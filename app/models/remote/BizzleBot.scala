package models.remote

import
  concurrent.duration._

import
  akka.{ actor, pattern, util },
    actor.ActorRef,
    pattern.ask,
    util.Timeout

import
  play.api.{ libs, Logger },
    libs.{ json, iteratee },
      iteratee.Iteratee,
      json.JsValue

import
  models.workspace.{ ChatPacketProtocol, NetLogoControllerMessages, WebInstanceMessages },
    NetLogoControllerMessages.Halt,
    WebInstanceMessages.{ Connected, Join }

import play.api.libs.concurrent.Execution.Implicits.defaultContext

/*
Description:
  An automated bot for being a good samaritan towards NetLogo users
  Created by yours truly, J-Bizzle, botmaker extraordinaire
*/
//@ Make private[remote]
class BizzleBot(room: ActorRef, nlController: ActorRef) extends ChatPacketProtocol {

  implicit val timeout = Timeout(1.second)

  val BotName = "BizzleBot"

  private val Commands = List("commands", "help", "info", "whoami", "halt")

  def start() {
    room ? (Join(BotName)) map {
      case Connected(robotChannel) =>
        robotChannel |>> Iteratee.foreach[JsValue] {
          event =>
            Logger(BotName).info(event.toString())
            (event \ UserKey).asOpt[String].flatMap (user => (event \ MessageKey).asOpt[String] map ((user, _))).
              foreach { case (username, message) => handleChat(username, message) }
        }
    }
  }

  def canFieldMessage(message: String) = message.startsWith("/") && Commands.contains(message.tail)

  def offerAssistance(username: String, message: String) : Option[String] = {

    def preprocess(message: String) : Option[String] = {
      val trimmed = message.trim
      if (trimmed.startsWith("/")) Some(trimmed.tail.trim) else None
    }

    preprocess(message) map {

      case "commands" =>
        "here are the supported commands: " + Commands.mkString("[", ", ", "]")

      case "help" =>
        """|perhaps this can be of help to you:
          |
          |<ul><li>Press the Tab key to change agent contexts.</li>
          |<li>Press the Up Arrow/Down Arrow to navigate through previously-entered commands.</li>
          |<li>Press Control + L to clear the chat buffer.</li>
          |<li>Press Control + Shift + [any number key 1-5] to directly set yourself to use a specific agent context.</li>
          |<li>For information about how to use the NetLogo programming language, please consult  <a href=\"http://ccl.northwestern.edu/netlogo/docs/\">the official NetLogo user manual</a>.</li></ul>
        """.stripMargin

      case "info" =>
        """|NetLogo is a multi-agent programmable modeling environment,
          | authored by Uri Wilensky and developed at Northwestern University's Center for Connected Learning.
          |  For additional information, please visit <a href=\"http://ccl.northwestern.edu/netlogo/\">the NetLogo website</a>.
        """.stripMargin.replaceAll("""\n|\r""", "") // Remove the newlines; they're just in there to make the string presentable in the code here

      case "whoami" =>
        "you're @%s, obviously!".format(username)

      case "halt" =>
        nlController ! Halt
        "halting"

      case _ =>
        "you just sent me an unrecognized request.  I don't know how you did it, but shame on you!"

    } map ("@%s, ".format(username) + _)

  }

  // We can do stuff with this later, if we ever want to have the bot play with more-general chat
  protected def handleChat(username: String, message: String) {}

}


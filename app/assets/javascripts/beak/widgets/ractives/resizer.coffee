window.RactiveResizer = Ractive.extend({

  _isLocked:    false     # Boolean
  _xAdjustment: undefined # Number
  _yAdjustment: undefined # Number

  data: -> {
    isEnabled: false # Boolean
  , isVisible: true  # Boolean
  , target:    null  # Ractive
  }

  computed: {
    dims: ->
      """
      position: absolute;
      left: #{@get('left')}px; top: #{@get('top')}px;
      width: #{@get('width')}px; height: #{@get('height')}px;
      """
    midX:   -> (@get( 'width') / 2) - 5
    midY:   -> (@get('height') / 2) - 5
    left:   -> @get('target').get(  'left') - 5
    right:  -> @get('target').get( 'right') + 5
    top:    -> @get('target').get(   'top') - 5
    bottom: -> @get('target').get('bottom') + 5
    height: -> @get('bottom') - @get( 'top')
    width:  -> @get( 'right') - @get('left')
  }

  # () => Unit
  clearTarget: ->
    target = @get('target')
    if not @_isLocked and target?
      if not target.destroyed
        target.find('.netlogo-widget').classList.remove('widget-selected')
      @set('target', null)
    return

  # (Ractive) => Unit
  setTarget: (newTarget) ->
    if not @_isLocked
      setTimeout((=> # Use `setTimeout`, so any pending `clearTarget` resolves first --JAB (12/6/17)
        @clearTarget()
        @set('target', newTarget)
        newTarget.find('.netlogo-widget').classList.add('widget-selected')
      ), 0)
    return

  # (Ractive) => Unit
  lockTarget: (newTarget) ->
    if not @_isLocked and newTarget?
      @setTarget(newTarget)
      @_isLocked = true
    return

  # () => Unit
  unlockTarget: ->
    @_isLocked = false
    return

  on: {

    'start-handle-drag': (event) ->
      CommonDrag.dragstart.call(this, event, (-> true), (x, y) =>
        { x, y } = @find('.widget-resizer').getBoundingClientRect()
        @_xAdjustment = x - @get('left')
        @_yAdjustment = y - @get('top')
      )

    'drag-handle': (event) ->

      isSnapping = not event.original.ctrlKey

      CommonDrag.drag.call(this, event, (x, y) =>

        target    = @get('target')
        oldLeft   = target.get('left')
        oldRight  = target.get('right')
        oldTop    = target.get('top')
        oldBottom = target.get('bottom')

        left   = ['left'  , x - @_xAdjustment]
        right  = ['right' , x - @_xAdjustment]
        top    = ['top'   , y - @_yAdjustment]
        bottom = ['bottom', y - @_yAdjustment]

        direction = event.original.target.dataset.direction

        adjusters =
          switch direction
            when "Bottom"     then [bottom]
            when "BottomLeft" then [bottom, left]
            when "BottomRight"then [bottom, right]
            when "Left"       then [left]
            when "Right"      then [right]
            when "Top"        then [top]
            when "TopLeft"    then [top, left]
            when "TopRight"   then [top, right]
            else throw new Error("What the heck resize direction is '#{direction}'?")

        clamp = (dir, value) =>
          opposite =
            switch dir
              when 'left'   then 'right'
              when 'right'  then 'left'
              when 'top'    then 'bottom'
              when 'bottom' then 'top'
              else throw new Error("What the heck opposite direction is '#{dir}'?")
          oppositeValue = @get(opposite)
          if opposite is 'left' or opposite is 'top'
            Math.max(value, oppositeValue + 35)
          else
            Math.min(value, oppositeValue - 35)

        snapToGrid = (n) -> n - (n - (Math.round(n / 10) * 10))

        for [dir, currentCor] in adjusters
          snapped = if isSnapping then snapToGrid(currentCor) else currentCor
          target.set(dir, clamp(dir, snapped))

        @get('target').fire('widget-resized'
                           , oldLeft           , oldRight           , oldTop           , oldBottom
                           , target.get('left'), target.get('right'), target.get('top'), target.get('bottom')
                           )

      )

    'stop-handle-drag': ->
      CommonDrag.dragend.call(this, =>
        @_xAdjustment = undefined
        @_yAdjustment = undefined
      )

  }


  # coffeelint: disable=max_line_length
  template:
    """
    {{# isEnabled && isVisible && target !== null }}
    <div class="widget-resizer" style="{{dims}}">
      {{ #target.get("resizeDirs").includes("bottom")      }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Bottom"      style="cursor:  s-resize; bottom:          0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomLeft")  }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="BottomLeft"  style="cursor: sw-resize; bottom:          0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("bottomRight") }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="BottomRight" style="cursor: se-resize; bottom:          0; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("left")        }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Left"        style="cursor:  w-resize; bottom:   {{midY}}; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("right")       }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Right"       style="cursor:  e-resize; bottom:   {{midY}}; right:         0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("top")         }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="Top"         style="cursor:  n-resize; top:             0; left:   {{midX}};"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topLeft")     }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="TopLeft"     style="cursor: nw-resize; top:             0; left:          0;"></div>{{/}}
      {{ #target.get("resizeDirs").includes("topRight")    }}<div draggable="true" on-drag="drag-handle" on-dragstart="start-handle-drag" on-dragend="stop-handle-drag" class="widget-resize-handle" data-direction="TopRight"    style="cursor: ne-resize; top:             0; right:         0;"></div>{{/}}
    </div>
    {{/}}
    """
  # coffeelint: enable=max_line_length

})

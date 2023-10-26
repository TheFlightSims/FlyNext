var cdu = nil;

var CDU = {

    isRightLSK: func(lsk)
    {
        return (lsk[0] == `R`);
    },
    
    lineForLSK: func(lsk)
    {
        return (lsk[1] - `1`);
    },

    Field : {
        new : func(tag = nil, title = nil, pos = nil, rows = 1, dynamic = 0, selectable = 0)
        {
          m = {parents:[CDU.Field]};
          m._page = nil;
          m._title = title;
          
          m._selectable = selectable;
          m.tag = tag;
          m._line = 0;
          m._lineCount = rows;
          m.dynamic = dynamic;
          m.alignRight = 0;
          
          if (pos != nil) m._setFromLSK(pos);
    
          return m;
        },  
        
        createWithLSKAndTag : func(lsk, title, tag)
        {
            var m = CDU.Field.new(tag);
            m._setFromLSK(lsk);
            m._title = title;
            return m;
        },
    
        isSelectable: func { me._selectable; },
        getPage: func { me._page; },
        setPage: func(p) {  me._page = p; },
        
        firstLine: func { me._line; },
        lineCount: func { me._lineCount; },
        
        _setFromLSK: func(lsk)
        {
            me._line = CDU.lineForLSK(lsk);
            me.alignRight = CDU.isRightLSK(lsk);
            me.column = me.alignRight ? CDU.NUM_COLS - 1 : 0;
            
            # check for column offset value
            if ((size(lsk) > 2) and (lsk[2] == `+`)) {
                var offset = lsk[3] - `0`;
                me.column += me.alignRight ? -offset : offset;
            }
        },
        
        update: func(cdu)
        {            
            var visRange = me._page.visibleIndices(me);
            if (visRange == nil) return; # empty vis range, dont display at all
            
          #  debug.dump('field has visible range ', me.tag, visRange);
            var line = visRange.firstLine;
            for (var index=visRange.firstIndex; index <= visRange.lastIndex; index += 1) {
                me._displayOnLine(cdu, index, line);
                line += 1;
            }
        },
        
        # internal helper to put a particular field offset onto an
        # absolute CDU line.
        _displayOnLine: func(cdu, index, absLine)
        {
            var row = cdu.rowForLineTitle(absLine);
            var s = me.titleData(index);
        # check if we have a valid title string
            if (s and (size(s) > 0)) {
                s = me.alignRight ? s : (" " ~ s);
                cdu.setRowText(row, me.column, me.alignRight, s);
            }
            
            row += 1; # increment for data row
            cdu.setRowText(row, me.column, me.alignRight, me.data(index));
        },
        
        titleData: func(offset)
        {
            if (me._title != nil) return me._title;
            if (me.tag == nil) return ''; # not tag, no title, blank
            return me._page.titleDataForField(me.tag, offset);
        },
        
        data: func(offset)
        {
            return me._page.dataForField(me.tag, offset);
        },
        
        edit: func(offset, scratch)
        {
            if (me.tag == nil) return 0; # not editable
            return me._page.editDataForField(me.tag, offset, scratch);
        },
        
        select: func(index) {
            if (me.tag == nil) return -1; # not selectable
            return me._page.selectField(me.tag, index);
        },
        
        copyData: func(lsk)
        {
            var index = me._page.indexForLine(me, CDU.lineForLSK(lsk));
            if ((CDU.isRightLSK(lsk) != me.alignRight) or (index < 0) or (index >= me.lineCount()))
                return nil;
            
            var d = me.data(index);
            if ((d == nil) or (size(d) == 0))
                return nil;
            
        # if we contain placeholder, dont return that             
            if ((d[0] == `#`) or (substr(d, 0, 2) == '--'))
                return nil;
            
        # convert to large font, remove display data
            d = string.replace(d,'_','');
            d = string.replace(d,'~','');
            d = string.replace(d,'g','');
            
            return d;
        },
        
        enterData: func(lsk, scratch)
        {
            var index = me._page.indexForLine(me, CDU.lineForLSK(lsk));
            if ((CDU.isRightLSK(lsk) != me.alignRight) or (index < 0) or (index >= me.lineCount()))
                return -1;
            
            return me.edit(index, scratch);
        },
        
        selectData: func(lsk)
        {
            var index = me._page.indexForLine(me, CDU.lineForLSK(lsk));
            if ((CDU.isRightLSK(lsk) != me.alignRight) or (index < 0) or (index >= me.lineCount()))
                return -1;
                
            return me.select(index);
        }
    },
    
    ############################################################################
    # ScrolledField is used in MultiPages, queries some data from the model
    # and optimises updates differently
    ############################################################################
    ScrolledField: {
        new : func(tag, dynamic = 0, selectable = 0, alignRight = 0)
        {
            var base = CDU.Field.new(tag:tag, dynamic:dynamic, selectable:selectable);
            base.alignRight = alignRight;
            base.column = alignRight ? CDU.NUM_COLS - 1 : 0;
            
            m = {parents:[CDU.ScrolledField, base]};
            return m;  
        },  
        
    # our line count always comes from the model
        lineCount: func { 
            return me.getPage().getModel().lineCountFor(me.parents[1].tag);
        },
    },
    
    ############################################################################
    # Action is a simple structure with optional title, always an lsk, done via 
    # callbacks.
    ############################################################################
    Action: {
      new : func(lbl, lsk, cb = nil, enableCb = nil, title = nil)
      {
          m = {parents:[CDU.Action]};
          m._label = lbl;
          m.lsk = lsk;
          m._callback = cb;
          m._enabled = enableCb;
          m._title = title;
          return m;  
      },  
        
      exec: func
      {
          if (me._callback != nil) {
              me._callback();
          } else {
              debug.dump("dummy action executed:" ~ me.label);
          }
      },
      
      isEnabled: func
      {
          if (me._enabled != nil) {
              return me._enabled();
          } else {
              return 1;
          }
      },
      
      title: func { me._title; },
      label: func { me._label; },
      showArrow: func { 1 },

      update: func(cdu)
      {
          var rightAlign = CDU.isRightLSK(me.lsk);
          var s = me.label();
          if (me.showArrow()) {
              s = rightAlign ? (s ~ ">") : ("<" ~ s);
          }
          var col = rightAlign ? CDU.NUM_COLS - 1 : 0;
          var line = CDU.lineForLSK(me.lsk);
            cdu.setRowText(cdu.rowForLine(line), col, rightAlign, s);

          var t = me.title();
          if (t != nil) {
            cdu.setRowText(cdu.rowForLineTitle(line), col, rightAlign, t);
          }
          return line;
      }
    },

    ############################################################################
    # Base class for page models. Routes requests to methods based on tag
    # values, but this can be over-ridden of course.
    ############################################################################
    AbstractModel : {
        
        new : func()
        {
            m = { parents:[CDU.AbstractModel]};
            m.clearModifedData();
            return m;
        },
        
        data: func(tag, offset)
        {
            # allow easy overriding when modifcation is pending
            if (contains(me._modData, tag)) 
                return me._modData[tag];

            var method = "dataFor" ~ tag;
            return me._callTagMethod(method, [offset], nil);
        },
    
        editData: func(tag, offset, scratch)
        {
            var method = "edit" ~ tag;
            return me._callTagMethod(method, [scratch, offset], -1);
        },
    
        titleData: func(tag, offset)
        {
            var method = "titleFor" ~ tag;
            return me._callTagMethod(method, [offset], nil);
        },
        
        pageStatus: func(page) nil,

        setModifiedData: func(tag, data) {
            me._modData[tag] = data;
        },

        clearModifedData: func {
            me._modData = {};
        },

        # overrideable function to have dynamic page title
        pageTitle: func(page) nil,

        lineCountFor: func(tag) { me._callTagMethod('countFor' ~ tag, [], 0); },
        firstLineFor: func(tag) { me._callTagMethod('firstLineFor' ~ tag, [], 0); },
        select: func(tag, index) { me._callTagMethod('select' ~ tag, [index], -1); },
        
        #overrideable function to process willDisplay in the model
        willDisplay: func(page) 0,
        willUndisplay: func(page) 0,

        _callTagMethod: func(name, invokeArgs, defaultResult) {
            var f = me._findMethod(name, me);
            if (f==nil) return defaultResult;
            
            var ret = call(f, invokeArgs, me, var err = []);
            if (size(err) > 0) {
                debug.dump('failure running tag method ' ~ name);
                debug.printerror(err);
                return defaultResult;
            }
            
            return ret;
        },
        
        _findMethod: func(nm, obj) { 
            # local test
            if (contains(obj, nm) and (typeof(obj[nm]) == 'func')) return obj[nm];  
            if (contains(obj, 'parents')) {
                foreach (var pr; obj['parents']) {
                    var f = me._findMethod(nm, pr);
                    if (f != nil) return f; # found
                }
            }
            
            return nil;
        }
    },

    ############################################################################
    # Base class for CDU pages. You can subclass this, but probably not advised.
    # Better to define new field types or use a model to achieve what you need.
    ############################################################################
    Page : {
        new : func(owner, title = 'UNNAMED', model = nil, dynamicActions = 0, tag = '')
        {
            m = { 
                parents:[CDU.Page],
                _previousPage: nil,
                _nextPage: nil,
                baseTitle: title,
                _actions: [],
                _fields: [],
                _model: model,
                _dynamicActions: dynamicActions,
                fixedSeparator: [99,99],
                _tag: tag,
                _cdu: owner,
                _status: CDU.STATUS_NONE
            };

            if (tag == '')
                m._tag = '__' ~ title;

            return m;
        },
    
    # compute our title
        title: func
        {
            var t = me.baseTitle;
            var status = me.pageStatus();
            if (me._cdu._modExec) status = CDU.STATUS_MOD;

            # fixme, alignment is not quite right here
            if (status == CDU.STATUS_MOD) t = 'MOD ' ~ t;
            elsif (status == CDU.STATUS_ACTIVE) t = 'ACT ' ~ t;

            # no siblings, simple
            if ((me._previousPage == nil) and (me._nextPage == nil))
                return t;
                
            var pgIndex = 0;
            var pgCount = 0;
            var pg = me.firstPage();
        
        # walk forwards to find ourselves and the list end
            while (pg != nil) {
                if (pg == me) pgIndex = pgCount; # ourselves
                pgCount += pg.pageCount();
                pg = pg._nextPage;
            }
        
        # position page index at far right (but one)
            var pgText = " ~"~(pgIndex + 1) ~ "/" ~ pgCount;
            while(size(t) < CDU.NUM_COLS-size(pgText))
                t ~= " ";
            
            return t~pgText;
        },
        
        pageStatus: func { 
            # model can override status
           if (me._model != nil) {
               var s = me._model.pageStatus(me);
               if (s != nil) return s;
           }
           return me._status; 
        },

        setPageStatus: func(s) {
            me._status = s;
        },

        tag: func { me._tag; },
        
    # fields
        getFields: func
        {
            return me._fields;
        },
        
        addField: func(fld) { me._addField(fld); },
        
        # inheritable version, so derived classes can call us safely
        _addField: func(fld)
        {
            fld.setPage(me);
            append(me._fields, fld);
        },
        
    # paging
        nextPage: func { (me._nextPage == nil) ? me.firstPage() : me._nextPage;},
        previousPage: func { (me._previousPage == nil) ? me.lastPage() : me._previousPage; },
        
        firstPage: func {    
            (me._previousPage == nil) ? me : me._previousPage.firstPage(); # recursion is fun
        },

        lastPage: func {
            (me._nextPage == nil) ? me : me._nextPage.lastPage();
        },

        pageIndex: func {
            var pgIndex = 0;
            var pgCount = 0;
        
        # walk forwards to find ourselves and the list end
            for (var pg = me.firstPage(); pg != nil; pg = pg._nextPage) {
                if (pg == me) return pgCount; # ourselves
                pgCount += pg.pageCount();
            }

            # should never be hit, implies broken page logic
            return nil;
        },

        # override for multi-page
        pageCount: func 1,

    # actions
        getActions: func()
        {
            return me._actions;
        },
        
        addAction: func(act)
        {
            append(me._actions, act);
        },
    
        hasDynamicActions: func { me._dynamicActions; },
        refreshDynamicActions: func(cdu) {
            me._refreshDynamicActions(cdu);
        },
        
    # model data
        setModel: func(m) { me._model = m; },
        getModel: func { me._model; },
    
        titleDataForField: func(tag, offset)
        {
            if (me._model != nil) {
                var d = me._model.titleData(tag, offset);
                if (d) return d;
            }
             
            return nil;   
        },
        
        dataForField: func(tag, offset)
        {
            if (me._model != nil) {
                var d = me._model.data(tag, offset);
                if (d) return d;
            }
                
            return nil;
        },
        
        selectField: func(tag, index)
        {
            if (me._model != nil) {
                var d = me._model.select(tag, index);
                if (d >= 0) return d;
            }
                
            return -1;
        },
        
        editDataForField: func(tag, offset, scratch)
        {
            if (me._model != nil) {
                var d = me._model.editData(tag, offset, scratch);
                if (d >= 0) {
                    # found the tag, so we are done
                    return d;
                }
            }
              
            return nil;  
        },
    
    # display
        # over-rideable hook method when a page is displayed
        willDisplay: func(cdu, reason) { 
            if (me._model != nil) {
                me._model.willDisplay(me);
            }
        },
        
        # no-op by default, called when the page is replaced / cleared
        didUndisplay: func(cdu) { 
            if (me._model != nil) {
                me._model.willUndisplay(me);
            }
        },
    
        update: func(cdu)
        {
            cdu.setRowText(0, 0, 0, me.title());
            me._updateActions(cdu);
            
            foreach (var field; me._fields) {
                field.update(cdu);
            }
        },
        
    # map field indices to on-screen lines. These are simple versions, 
    # MultiPage overrides them to implement scrolling!
        indexForLine: func(field, line) { line - field.firstLine(); },
        visibleIndices: func(field)
        {
            return { firstIndex:0, lastIndex: field.lineCount() - 1, firstLine: field.firstLine()};
        },
        
        _updateActions: func(cdu)
        {
        # track the topmost (lowest numbered) action on each side
            var leftAct = me.fixedSeparator[0];
            var rightAct = me.fixedSeparator[1];
        
            foreach (var act; me._actions)
            {
                if (!act.isEnabled())
                    continue;
                
            # display the action; returns its line for computing
            # the seperator positions.
                var line = act.update(cdu);
                     
                if (CDU.isRightLSK(act.lsk)) {
                    rightAct = math.min(rightAct, line);
                } else {
                    leftAct = math.min(leftAct, line);
                }
            }
        
            #debug.dump('action separator rows', leftAct, rightAct);
        
            if (leftAct > 0 and leftAct < 99) 
                cdu.setRowText(cdu.rowForLineTitle(leftAct), 0, 0, '------------');
        
            if (rightAct > 0 and rightAct < 99)
                cdu.setRowText(cdu.rowForLineTitle(rightAct), CDU.NUM_COLS - 1, 1, '------------');
        },
        
        _refreshDynamicActions: func(cdu)
        {
            foreach (var act; me._actions) {
                if (!act.isEnabled())
                    continue;
               act.update(cdu);
           }
        },
    },
    
    ############################################################################
    # Page with several screens of information. Only supports two columns,
    # but stacks its Fields up in the order they are added.
    ############################################################################
    MultiPage : {
        new : func(cdu, model, title, linesPerPage = 5, dynamicActions = 0,
            basePageIndex = 0)
        {
            var base = CDU.Page.new(owner:cdu, title:title, model:model, dynamicActions:dynamicActions);
            m = { parents:[CDU.MultiPage, base]};
            m._linesPerPage = linesPerPage;
            m._leftStack = [];
            m._rightStack = [];
            m._screen = 0;
            m._basePageIndex = basePageIndex;
            return m;
        },
        
        title: func { 
            var base = (me._previousPage != nil) ? (me._previousPage.pageIndex() + 1) : 0;
            var pgText = " ~"~(me._screen + 1 + base) ~ "/" ~ (me.numPages() + base);
            
            var pgTitle = me.baseTitle;
            var status = me.pageStatus();
            if (me._cdu._modExec) status = CDU.STATUS_MOD;

            # fixme, alignment is not quite right here
            if (status == CDU.STATUS_MOD) pgTitle = 'MOD ' ~ pgTitle;
            elsif (status == CDU.STATUS_ACTIVE) pgTitle = 'ACT ' ~ pgTitle;

            while(size(pgTitle) < CDU.NUM_COLS-size(pgText)-1)
                pgTitle ~= " ";
            return pgTitle~pgText;
        },
        
        numPages: func
        {
            var leftRows = 0;
            foreach (var fld; me._leftStack) leftRows += me._model.lineCountFor(fld.tag);
            var rightRows = 0;
            foreach (var fld; me._rightStack) rightRows += me._model.lineCountFor(fld.tag);
            
            var totalRows = math.max(leftRows, rightRows);
            totalRows += (me._linesPerPage - 1); # round up
            return int(totalRows / me._linesPerPage);
        },

        pageCount: func { me.numPages(); },
        
        addField: func(fld)
        {
            me._addField(fld);
            append(fld.alignRight ? me._rightStack : me._leftStack, fld);
        },
        
        indexForLine: func(field, line) 
        { 
            var virtualLine = line + (me._screen * me._linesPerPage);
            return virtualLine - me._model.firstLineFor(field.tag);
        },
        
        visibleIndices: func(field)
        {
            var screenOffset = (me._screen * me._linesPerPage);
            var lastVisible = screenOffset + me._linesPerPage - 1;
            
            var fieldStart = me._model.firstLineFor(field.tag);
            var fieldEnd = fieldStart + me._model.lineCountFor(field.tag) - 1;
            
        # if ranges dont overlap, return nil since field is invisible
            if ((fieldEnd < screenOffset) or (fieldStart > lastVisible)) return nil;
            
        # find smallest overlap
            var firstLine = 0;
            var fieldBase = fieldStart;
            
            if (fieldStart < screenOffset) {
                fieldStart = screenOffset;
            } else if (fieldStart > screenOffset) {
                firstLine += (fieldStart - screenOffset);
            }
            
            if (fieldEnd > lastVisible) {
                fieldEnd = lastVisible;
            }
        # package up and return
            return { firstIndex:fieldStart - fieldBase, 
                     lastIndex:fieldEnd - fieldBase, 
                     firstLine: firstLine};
        },

        reloadModel: func {
            me._screen = 0;
            me.update(me._cdu);
        },
        
    # paging
        willDisplay: func(cdu, reason) { 
            if (cdu.currentPage() == me) {
                # cycling within the multi-page
                if (reason == CDU.DISPLAY_NEXT) {
                    me._screen += 1;
                    if (me._screen >= me.numPages()) me._screen = 0; # wrap
                } elsif (reason == CDU.DISPLAY_PREVIOUS) {
                    me._screen -= 1;
                    if (me._screen < 0) me._screen = me.numPages() - 1;
                }
            } else {
                # we're entering the multipage from a different page,
                # we may need to reset to the correct point
                if ((reason == CDU.DISPLAY_NEXT) or (reason == CDU.DISPLAY_BUTTON)) me._screen = 0;
                if (reason == CDU.DISPLAY_PREVIOUS) {
                    me._screen = me.numPages() - 1;
                }
            }
            
            if (me._model != nil) {
                me._model.willDisplay(me);
            }
        },

        nextPage: func { 
            if ((me._screen + 1) >= me.numPages()) {
                # this works because multi-pages are
                # adfter fixed ones (legs/route)
                return me.firstPage();
            }

            return me;
        },

        previousPage: func {
            if ((me._screen - 1) < 0) {
                if (me._previousPage != nil)
                    return me._previousPage;
            }

            return me;
        }
    },

    canvas_settings: {
        "name": "CDU",
        "size": [512, 512],
        "view": [480, 480],
        "mipmapping": 1,
    },
    
    NUM_COLS: 24,
    NUM_ROWS: 14,      # 6 main rows, 6 title rows, page title and scratch
    MARGIN: 30,
    MARGIN_BOTTOM: 57, # needed because the screen is not a square
    SCRATCHPAD_ROW: 13,

    EMPTY_FIELD4: '----',
    EMPTY_FIELD5: '-----',
    EMPTY_FIELD10: '----------',
    
    BOX2: '__',
    BOX2_1: '__._',
    BOX3: '___',
    BOX3_1: '___._',
    BOX4: '____',
    BOX5: '_____',

    # enum of page display reasons. 
    DISPLAY_BUTTON: 0,
    DISPLAY_NEXT: 1,
    DISPLAY_PREVIOUS: 2,
    DISPLAY_PUSH: 3,
    DISPLAY_POP: 4,

    MSG_CRITICAL: 1,
    MSG_WARN: 2,
    INVALID_DATA_ENTRY: 3,
    MSG_INFO: 4,

    STATUS_NONE: 0,
    STATUS_ACTIVE: 1,
    STATUS_MOD: 2,

    new : func(prop1, placement)
    {
        m = { parents : [CDU]};

        m.rootNode = props.globals.initNode(prop1);
   
        m.scratch = "";
        m.scratchNode = m.rootNode.initNode("scratch", "", "STRING");

        var outputs = m.rootNode.initNode("outputs");
        m._outputExec = outputs.initNode("exec", 0, "BOOL");
        m._outputMessage = outputs.initNode("message", 0, "BOOL");
        m._canExecNode = m.rootNode.initNode("can-exec", 0, "BOOL");

        m._oleoSwitchNode = props.globals.getNode('instrumentation/fmc/discretes/oleo-switch-flight', 1);
        
        m._setupCanvas(placement);
        m._setupCommands();

        m._page = nil;
        m._model = nil;
        m._pages = {};
        m._savedPage = nil;
        m._model = CDU.AbstractModel.new(); # empty model for fallback
        m._dynamicFields = [];
        m._messages = [];
        m._cancelExecCallback = nil;
        m._modExec = 0; # flag indicating if exec callbacl is a page mod

        m.currTimerSelf = 0; # timer for key presses
        
        m._updateId = 0;
        m._clearTimer = maketimer(1.0, func m._clearTimeout(); );

        return m;
    },
    
    _setupCanvas: func(placement)
    {
        me._canvas = canvas.new(CDU.canvas_settings);        
        var text_style = {
            'font': "BoeingCDU-Large.ttf",
            'character-size': 28,
            'alignment': 'left-bottom'
        };
        var text_style_s = {
            'font': "BoeingCDU-Small.ttf",
            'character-size': 28,
            'alignment': 'left-bottom'
        };
        
        var cduNode = props.globals.getNode('/instrumentation/cdu/', 1);
        cduNode.initNode('brightness-norm', 0.5, 'DOUBLE');
        
        var displayType = getprop('/instrumentation/cdu/settings/display');
        if (displayType == 'crt')
            me._canvas.setColorBackground(0.0, 0.05, 0.0);
        else
            me._canvas.setColorBackground(0.05, 0.05, 0.05);
        
        me._canvas.addPlacement(placement);
        me._scene = me._canvas.createGroup();
        me._scene.setTranslation(CDU.MARGIN, CDU.MARGIN);
        
        # create line elements
        me._texts = [];
        me._texts_s = [];
        
        var rowHeight = CDU.canvas_settings.view[1] - (CDU.MARGIN * 2 + CDU.MARGIN_BOTTOM);
        var cellH = rowHeight / CDU.NUM_ROWS;
        
        for (var r=0; r<CDU.NUM_ROWS; r = r+1) {
            var txt = me._scene.createChild("text");
            
            txt._node.setValues(text_style);
            
            if (displayType == 'crt')
                txt.setColor(0,1,0);
            else
                txt.setColor(0.9,0.9,0.9);
                
            txt.setTranslation(0.0, (r + 1.2) * cellH);
            append(me._texts, txt);
            
            var txt_s = me._scene.createChild("text");
            
            txt_s._node.setValues(text_style_s);
            
            if (displayType == 'crt')
                txt_s.setColor(0,1,0);
            else
                txt_s.setColor(0.9,0.9,0.9);
            
            txt_s.setTranslation(0.0, (r + 1.2) * cellH);
            append(me._texts_s, txt_s);
        }
    },

    _buttonCallbackTable: {
        'exec':     func() { Boeing.cdu.button_exec(); },
        'prog':     func() { Boeing.cdu.displayPageByTag('progress'); },
        'hold':     func() { print("Not implemented yet");},
        'cruise':   func() { Boeing.cdu.displayPageByTag('cruise'); },
        'dep-arr':  func() { Boeing.cdu.button_dep_arr(); },
        'legs':     func() { Boeing.cdu.button_legs(); },
        'menu':     func() { Boeing.cdu.displayPageByTag('menu'); },
        'climb':    func() { Boeing.cdu.displayPageByTag('climb'); },
        'fix':      func() { Boeing.cdu.displayPageByTag('fix'); },
        'n1-limit': func() { Boeing.cdu.displayPageByTag('thrust-lim');},
        'route':    func() { Boeing.cdu.button_route(); },
        'next-page': func() { Boeing.cdu.next_page(); },
        'prev-page': func() { Boeing.cdu.prev_page(); },
        'descent':  func() { Boeing.cdu.displayPageByTag('descent'); },
        'init-ref': func() { Boeing.cdu.displayPageByTag('index'); },
        'clear':    func() { Boeing.cdu.clear(); },
        'delete':   func() { Boeing.cdu.delete(); },
        'plus-minus': func() { Boeing.cdu.plusminus(); }
    },

    _keyCommandCallback: func(node) 
    {
        var k = node.getChild("key").getValue();
        Boeing.cdu.input(chr(k));
    },

    _lskCommandCallback: func(node)
    {
        var keyName = node.getChild("lsk").getValue();
        Boeing.cdu.lsk(keyName);
    },

    # register commands used for interfacing external CDU hardware
    _setupCommands: func()
    {
        addcommand('cdu-key', me._keyCommandCallback);
        addcommand('cdu-lsk', me._lskCommandCallback);

        foreach(var b; keys(me._buttonCallbackTable)) {
            addcommand('cdu-button-' ~ b , me._buttonCallbackTable[b]);
        }

        addcommand('cdu-button-clear-up', func() { Boeing.cdu.clearRelease(); });
    },
    
    rowForLine: func(line)
    {
        return (line * 2) + 2;
    },
    
    rowForLineTitle: func(line)
    {
        return (line * 2) + 1;
    },
    
    displayPageByTag: func(tag)
    {
        if (!contains(me._pages, tag)) {
            debug.dump("no page with tag:" ~ tag);
            return;
        }
        
        var pg = me._pages[tag];
    # check if we're in flight mode
        var inflight = (me._oleoSwitchNode.getValue() == 1);
        if (inflight and contains(me._pages, tag ~ '-inflight')) {
            pg =  me._pages[tag ~ '-inflight'];
        }
        
        me.displayPage(pg, CDU.DISPLAY_BUTTON);
    },
    
    addPage: func(pg, tag)
    {
        me._pages[tag] = pg;
    },
    
    addPageWithFlightVariant: func(tag, preflight, flight)
    {
        me._pages[tag] = preflight;
        me._pages[tag ~ '-inflight'] = flight;
    },
    
    # retrive the current page being displayed
    currentPage: func me._page,

    # display a new page
    displayPage: func(pg, reason = nil)
    {
        if (reason == nil) reason = CDU.DISPLAY_BUTTON;

        # note we don't do a pg == me._page check here,
        # becuase this is used to re-display multi-pages
        if (pg != nil) pg.willDisplay(me, reason);
        var oldPage = me._page;
        me._page = pg;
        me._refresh();
        if (oldPage != nil) oldPage.didUndisplay(me);
    },

    pushTemporaryPage: func(pg)
    {
        me._savedPage = me.currentPage();
        me.displayPage(pg, CDU.DISPLAY_PUSH);
    },

    popTemporaryPage: func 
    {
        if (me._savedPage == nil) {
            debug.dump('CDU: No saved page');
            return;
        }

        var saved = me._savedPage;
        me._savedPage = nil;
        me.displayPage(saved, CDU.DISPLAY_POP);
    },

    getPage: func(tag) {
        if (!contains(me._pages, tag)) {
            debug.dump("no page with tag:" ~ tag);
            return nil;
        }

        return me._pages[tag];
    },
    
    requestRefresh: func {
        me._refresh();
    },

    _refresh: func()
    {
        var pg = me._page;
        me._cleanup(); # blank everything except the S/P
        # refresh the scratch/message
        me._updateMessageDisplay();

        if (pg == nil) return;
        
        pg.update(me);
        me._dynamicFields = [];
        
        foreach (var field; pg.getFields()) {
            if (field.dynamic)
                append(me._dynamicFields, field);   
        }
        
        if (pg.hasDynamicActions() or (size(me._dynamicFields) > 0)) {
            # only update if we have dynamic fields/actions
            me._startUpdates();
        }
    },
    
    setRowText: func(row, col, alignRight, text)
    {
        # check for nil text or empty string
        if (typeof(text) != 'scalar') { 
            return; 
        }

        if ((row < 0) or (row >= CDU.NUM_ROWS)) {
            debug.die('invalid row index requested', row, col, text);
            return;
        }
        
        text = text ~ ''; # force stringificaton
        
        # split large and small font
        var textS = "";
        var textL = "";
        var text1 = split('!',text);
        foreach(var textItem; text1) {
            var text2 = split('~',textItem);
            textL ~= text2[0];
            while (size(textS) < size(textL))
                textS ~= ' ';
            if (size(text2) > 1)
                textS ~= text2[1];
            while (size(textL) < size(textS))
                textL ~= ' ';
        }
        
        var canavasTextL = me._texts[row];
        var charsL = canavasTextL.get('text') or "";
        var sz = size(textL);
        
        if (alignRight)
            colL = col - (sz - 1); # find left-most column
        else
            colL = col;
    
    # find left portion, pad with spaces to position

        var lpieceL = substr(charsL, 0, colL);
        while (size(lpieceL) < colL) {
            lpieceL = lpieceL ~ ' ';
        }
        
        var rpieceL = '';
    # preserve protion to the right of our insert
        if (size(charsL) > (colL + sz)) {
            rpieceL = substr(charsL, colL + sz);
        }

        canavasTextL.setText(lpieceL ~ textL ~ rpieceL);
        
        var canavasTextS = me._texts_s[row];
        var charsS = canavasTextS.get('text') or "";
        var sz = size(textS);
        
        if (alignRight)
            colS = col - (sz -1); # find left-most column
        else
            colS = col;
    
    # find left portion, pad with spaces to position
        var lpieceS = substr(charsS, 0, colS);
        while (size(lpieceS) < colS) {
            lpieceS = lpieceS ~ ' ';
        }
        
        var rpieceS = '';
    # preserve protion to the right of our insert
        if (size(charsS) > (colS + sz)) {
            rpieceS = substr(charsS, colS + sz);
        }
        
        canavasTextS.setText(lpieceS ~ textS ~ rpieceS);
    },
    
    clearRowText: func(row)
    {
        me._texts[row].setText('');
        me._texts_s[row].setText('');
    },
    
    _cleanup: func
    {
        # clear everything except the scratch pad, which
        # is handled seperartely in _refresh
        for (r=0; r<CDU.SCRATCHPAD_ROW; r=r+1)
            me.clearRowText(r);
    },
    
    _startUpdates: func
    {
        me._updateId += 1;
        settimer(func me._update(me._updateId), 1.0);
    },
    
    _update: func(upId)
    {
        upId == me._updateId or return;
        me._page.hasDynamicActions() or (size(me._dynamicFields) > 0) or return;
            
        if (me._page.hasDynamicActions()) {
            me._page.refreshDynamicActions(me);
        
        }
        
        foreach(var df; me._dynamicFields) {
            df.update(me);
        }
        
        settimer(func me._update(me._updateId), 1.0);
    },
     
################################################
# data formatters & parsers
     
     formatLatitude: func(lat)
     {
         var north = (lat >= 0.0);
         var latDeg = int(lat);
         var latMinutes = math.abs(lat - latDeg) * 60;
         return sprintf('%s%02dg%04.1f', north ? "N" : "S", abs(latDeg), latMinutes);
     },
     
     formatLongitude: func(lon)
     {
          var east = (lon >= 0.0);
          var lonDeg = int(lon);
          var lonMinutes = math.abs(lon - lonDeg) * 60;
          sprintf("%s%03dg%04.1f", east ? 'E' : 'W', abs(lonDeg), lonMinutes);        
     },
     
     formatLatLonString: func(obj)
     {
         var lat = 0;
         var lon = 0;
         if (isa(obj, geo.Coord)) {
             lat = obj.lat();
             lon = obj.lon();
         } else {
             lat = obj.lat;
             lon = obj.lon;
         }
         
         return me.formatLatitude(lat) ~ ' ' ~ me.formatLongitude(lon);    
     },
     
     formatAltitude: func(altFt)
     {
         if (altFt < -100) return CDU.EMPTY_FIELD5;
         
         var flightlLevel = int(altFt/ 100);
         if (flightlLevel >= 180) return sprintf('FL%3d', flightlLevel);
         return flightlLevel * 100;
     },
     
     parseAltitude: func(altString)
     {
       var sz = size(altString);
       if ((sz == 5) and (substr(altString, 0, 2) == 'FL')) {
           altString = substr(altString, 2);
           sz = 3;
       }
       
       if ((sz < 3) or (sz > 5)) return -9999;
       if (sz == 3) return num(altString) * 100;
       return num(altString);  
     },
     
     formatBearingSpeed: func(brg, spd)
     {
         if ((brg < 0) or (spd < 0)) return '---g/---';
         return sprintf('%03dg/%03d', brg, spd);
     },
     
     _farenheitToCelsius: func(f) { (f - 32.0) / 1.8; },
     
     parseTemperatureAsCelsius: func(input)
     {
         # if default is F, need to tweak this
        var p = CDU._parseSuffix(input);
        var isFarenheit = (p.suffix == 'F');
         var t = num(p.str);
         return isFarenheit ? _farenheitToCelsius(t) : t;
     },
     
     # dual field rules: enter both with a seperating '/'.
     # if there's no slash, it's the outboard field
     # to enter only the inboard field, there must be a preceeding slash
     # returns a two element array, with outboard element at 0, inboard at 1
     # missing elements are nil.
     parseDualFieldInput: func(input)
     {
         var s = string.trim(input);
         if (size(s) <= 0) return [nil,nil]; # empty input string
         
         var slashPos = find('/', s);
         if (slashPos < 0) return [s, nil]; # no slash, outboard only
         if (slashPos == 0) return [nil, substr(s, 1)]; # leading slash, inboard only
         return [substr(s, 0, slashPos), substr(s, slashPos + 1)];
     },
     
    parseBearingSpeed: func(input)
    {
        var fields = CDU.parseDualFieldInput(input);
        if (!fields[0] or !fields[1])
            return nil;
    
        var hdg = math.mod(num(fields[0]), 360);
        return {bearing:hdg, speed:num(fields[1])};
    },

    parseKnotsMach: func(input)
    {
        var fields = CDU.parseDualFieldInput(input);
        var r = { knots: nil, mach: nil};
        if (fields[0] != nil) {
            r.knots = num(fields[0]);
            if ((r.knots < 100) or (r.knots > 400)) return nil;
        }

        if (fields[1] != nil) {
            r.mach = num(mach[0]);
            if ((r.mach < 0.1) or (r.mach > 1.0)) return nil;
        }

        return r;
    },

    _parseSuffix: func(in)
    {
        if (!in) return nil;
        var s = string.trim(in);
        var lastChar = s[size(s) - 1];
        if (!string.isalpha(lastChar))
            return {str:s, suffix:''};

        s = substr(s, 0, size(s) - 1); # drop final char
        return {str:s, suffix:lastChar};
    },

    _parseRestrictionSuffix: func(s)
    {
        if (s == 'A') return 'above';
        if (s == 'B') return 'below';
        return 'at';        
    },

    parseSpeedAltitudeConstraint: func(input)
    {
        var r = {
            alt_cstr_type: nil,
            speed_cstr_type:nil
        };

        var fields = CDU.parseDualFieldInput(input);
        var spd = CDU._parseSuffix(fields[0]);
        var alt = CDU._parseSuffix(fields[1]);

        if (spd != nil) {
            r.speed_cstr_type = CDU._parseRestrictionSuffix(spd.suffix);
            r.speed_cstr = num(speed.str);
        }

        if (alt != nil) {
            r.alt_cstr_type = CDU._parseRestrictionSuffix(alt.suffix);
            r.alt_cstr = num(alt.str);
        }
        
        return r;
    },

    parseSpeedAltitude: func(input)
    {
        var r = {};
        var fields = CDU.parseDualFieldInput(input);
        if (fields[0] != nil) {
            r.knots = num(fields[0]);
        }

        if (fields[1] != nil) {
            r.altitude = CDU.parseAltitude(fields[1]);
        }
        
        return r;
    },

     formatMagVar: func(magvarDeg)
     {
         var east = (magvarDeg > 0);
         sprintf('%s%3d', east ? 'E':'W', abs(magvarDeg));
     },
     
     formatWayptSpeedAltitude: func(wp)
     {
         if (wp==nil) return nil;
             
         var altConstraintType = wp.alt_cstr_type;
         var speedConstraintType = wp.speed_cstr_type;
        
        if (altConstraintType == nil and speedConstraintType == nil) {
            return '----/------';
        }

         var altConstraint = '      '; # six spaces
         if (altConstraintType != nil)
             altConstraint = me.formatAltRestriction(wp);
        
         var speedConstraint = '';
         if (speedConstraintType != nil)
            speedConstraint = me.formatSpeedRestriction(wp);
        
         return speedConstraint ~ '/' ~ altConstraint;
     },

    # format a speed / altitude, but show forecase values
    # in small font if no explicit restriction is set
     formatWayptSpeedAltitudeWithForecast: func(wp, forecast)
     {
        var altConstraint = '';
        if (wp.alt_cstr_type != nil)
            altConstraint =  me.formatAltRestriction(wp);
        else 
            altConstraint = '~' ~ me.formatAltRestriction(forecast);

        var s = '';
        if (wp.speed_cstr_type != nil)
            s = me.formatSpeedRestriction(wp);
        else 
            s = '~' ~ me.formatSpeedRestriction(forecast);

        return s ~ '/' ~ altConstraint;
     },

     formatSpeed: func(speed)
     {
         if (speed < 1.0)
            return sprintf('.%3d', speed * 1000);
         sprintf(' %3d', speed);
     },

    formatSpeedMachKnots: func(mach, knots)
    {
        # tolerate either component being nil
        var machStr = '----';
        var knotsStr = '---';
        if (mach) machStr = sprintf('.%03d', mach * 1000);
        if (knots) knotsStr = sprintf('%3d', knots);
        return machStr ~ '/' ~ knotsStr;
    },

     formatSpeedAltitude: func(speed, alt)
     {
         return me.formatSpeed(speed) ~ '/' ~ me.formatAltitude(alt);
     },
     
     formatAltRestriction: func(wp)
     {
         var ty = wp.alt_cstr_type;
         s = me.formatAltitude(wp.alt_cstr);
         if (ty == 'at') s ~= ' '; 
         if (ty == 'above') s ~= 'A'; 
         if (ty == 'below') s ~= 'B';
         return s;
     },

     formatSpeedRestriction: func(wp)
     {
        var ty = wp.speed_cstr_type;
        s = me.formatSpeed(wp.speed_cstr);
        if (ty == 'at') s ~= ' '; 
        if (ty == 'above') s ~= 'A'; 
        if (ty == 'below') s ~= 'B';
        return s;
     },
     
    formatTimeDistace: func(time, distance)
    {
        # the seperator slash is small, hence the markup
        return me.formatTime(time) ~ '~/!' ~ me.formatDistanceNm(distance);
    },

    formatTime: func(time)
    {
        var hours = int(time / 3600.0);
        var minutes = time - (hours * 3600.0);

        # we want a single digit of minutes, so divide by 60 * 10
        minutes = int(minutes / 600.0); 
        return sprintf('%04d.%d~Z', hours, minutes);
    },

    # this assumes a 6-char field, 4 digits for the value and 2 for 'NM'
    formatDistance: func(d)
    {
        if (d < 10) {
            # when distance is below 10nm, show decimal
            return sprintf('%4.1f~NM', d);
        }

        return sprintf('%4d~NM', d);
    },

# button / LSK functions
    lsk: func(ident)
    {
        # check page action map for LSKs
        foreach (var act; me._page.getActions()) {
            if ((act.lsk == ident) and act.isEnabled()) {
                act.exec();
                me._refresh();
                return;
            }
        }
        
        foreach (var fld; me._page.getFields())
        {
            if (!fld.isSelectable()) continue;
            if (fld.selectData(ident) >= 0) {
                me._refresh();
                return;
            }
        }

        # don't allow entry from s/p or copying to it,
        # when messages are active
        if (me._haveMessages())
            return;
        
        if (size(me.scratch) > 0) {
            foreach (var fld; me._page.getFields())
            {
                var d = fld.enterData(ident, me.scratch);
                if (d == 1) {
                    me._updateScratch("");
                    me._refresh();
                    return;
                } elsif (d == 0) {
                    debug.dump("data validation error");
                    return;
                }
            }
        } else {
            foreach (var fld; me._page.getFields())
            {
                var d = fld.copyData(ident);
                if (d != nil) {
                    me._updateScratch(d);
                    return;
                }
            }
        }
        
        debug.dump('no action found for LSK');
    },
    
    button_init_ref: func
    {
        me.displayPageByTag("init-ref");
    },
    
    button_exec: func
    {
        if (!me.isExecActive()) {
            debug.dump('nothing to execute');
            return;
        }
        
        var cb = me._execCallback;
        me._execCallback = nil;
        me._cancelExecCallback = nil;
        me._canExecNode.setValue(0);
        me._outputExec.setValue(0);

        if (me._modExec) {
            me._modExec = 0;
            if (me._page.getModel() != nil) {
                me._page.getModel().clearModifedData();
            }
        }

        cb();
        me._refresh();
    },
    
    button_route: func
    {
        me.displayPageByTag("route");
    },
    
    button_legs: func
    {
        me.displayPageByTag("legs");
    },
    
    button_vnav: func
    {
        me.displayPageByTag("vnav");
    },
    
    button_nav_radios: func
    {
        me.displayPageByTag("nav-radios");
    },
    
    button_menu: func
    {
        me.displayPageByTag("menu");
    },
    
    button_dep_arr: func
    {
        me.displayPageByTag("departure-arrival");
    },
# page navigation
    prev_page: func
    {
        var pg = me._page.previousPage();
        if (pg != nil) {
            me.displayPage(pg, CDU.DISPLAY_PREVIOUS);
        } else {
            debug.dump('no prev page');
        }
    },
    
    next_page: func
    {
        var pg = me._page.nextPage();
        if (pg != nil) {
            me.displayPage(pg, CDU.DISPLAY_NEXT);
        } else {
            debug.dump('no next page');
        }
    },
    
    _updateScratch: func(newData)
    {
        me.scratch = newData;
        me.scratchNode.setValue(newData);
        
        # message block scratch display
        if (!me._haveMessages()) {
            me.clearRowText(CDU.SCRATCHPAD_ROW);
            me.setRowText(CDU.SCRATCHPAD_ROW, 0, 0, newData);
        }
    },

    input: func(data)
    {
        if (size(me.scratch) < CDU.NUM_COLS)
            me._updateScratch(me.scratch ~ data);
    },
    
    plusminus: func
    {
        var end = size(me.scratch);
        var lastchar = substr(me.scratch,end-1,end);
        if (lastchar == '+')
            me._updateScratch(substr(me.scratch,0,end-1)~'-');
        elsif (lastchar == '-')
            me._updateScratch(substr(me.scratch,0,end-1)~'+');
        else
            me.input('-');
    },
    
    delete : func
    {
        if (size(me.scratch) == 0)
            me._updateScratch('DELETE');
    },
    
    clear : func
    {
        if (me._haveMessages()) {
            me.clearMessage();
            return;
        }

        # Remove last character
        me._updateScratch(substr(me.scratch, 0, size(me.scratch) - 1));
        
        # Clear entire scratchpad when press and hold for 1 sec
        me._clearTimer.start();
    },

    _clearTimeout: func { me._updateScratch(''); },
    
    clearRelease : func
    {
        me._clearTimer.stop();
    },
    
    message : func(msg)
    {
        print("FIXME using old message API");
        cdu.postMessage(1, msg);
    },
    
    getScratchpad: func { me.scratch; },
    
    setScratchpad: func(x)
    {
        me._updateScratch(x);
    },
    
    clearScratchpad : func
    {
        me._updateScratch("");
    },

##################################
# messages api

    postMessage: func(level, text)
    {
        var newMessages = me._messages;
        append(newMessages, {text: text, level:level});
        me._messages = sort(newMessages, func(a,b) { return a.level - b.level;} );
        me._updateMessageDisplay();
        me._outputMessage.setValue(1);
    },

    clearMessage: func 
    {
        me._messages = (size(me._messages) == 1) ? [] : me._messages[1:]; # pop the front item
        me._updateMessageDisplay();
        if (!me._haveMessages()) {
            me._outputMessage.setValue(0);
        }
    },

    _updateMessageDisplay: func
    {
        me.clearRowText(CDU.SCRATCHPAD_ROW);
        if (!me._haveMessages()) {
            # show the scratchpad
            me.setRowText(CDU.SCRATCHPAD_ROW, 0, 0, me.scratch);
            return;
        }

        var msg = me._messages[0];
        # show highest priority (first) message
        me.setRowText(CDU.SCRATCHPAD_ROW, 0, 0, msg.text);
    },

    _haveMessages: func { size(me._messages) > 0 },

################################################
## exec API

    setExecCallback: func(exec)
    {
        debug.bt('Legacy EXEC call');
        me.setupExec(exec);
    },

    isExecActive: func 
    {
        return (me._execCallback != nil);
    },

    setupExec: func(exec, cancel = nil, modPage = 0)
    {
        me._modExec = modPage;
        me._execCallback = exec;
        me._cancelExecCallback = cancel;

        # show the lamp
        me._canExecNode.setValue(1);
        me._outputExec.setValue(1);
    },

    clearExec: func {
        me._execCallback = nil;
        me._cancelExecCallback = nil;
        me._modExec = 0;
    },

    cancelExec: func {
        var cb = me._cancelExecCallback;
        me.clearExec();
        if (cb != nil)
           cb();
    },

##################################
    StaticField : {
        new: func(pos, title = nil, data = nil)
        {
          m = {parents: [CDU.StaticField, CDU.Field.new(title:title, pos:pos)]};
          m._data = data;
          return m;
        },
        
        
        data: func(offset)
        {
            return me._data;
        }
    },
    
##################################
    NasalField : {
        new: func(pos, title, readCb, writeCb = nil)
        {
          m = {parents: [CDU.NasalField, CDU.Field.new(title:title, pos:pos)]};
          m._readCallback = readCb;
          m._writeCallback = writeCb;
          return m;
        },
        
        data: func(offset)
        {
            return me._readCallback(me.tag);
        },
        
        edit: func(offset, scratch)
        {
            if (me._writeCallback == nil) {
                debug.dump("field has no write callback");
                return 0;
            }
            
            return me._writeCallback(scratch);
        }
    },   
    
##################################
    PropField : {
        new: func(pos, prop, title = nil)
        {
          m = {parents: [CDU.PropField, CDU.Field.new(title:title, pos:pos)]};
          m._prop = prop;
          return m;
        },
        
        data: func(offset)
        {
            return getprop(me._prop);
        }
    },
    
    EditablePropField : {
        new: func(pos, prop, title = nil)
        {
          m = {parents: [CDU.EditablePropField, CDU.PropField.new(pos:pos, title:title, prop:prop)]};
          return m;
        },
        
        edit: func(offset, scratch)
        {
            setprop(me._prop, scratch);
            return 1;
        }
    },
    
#############
    linkPages: func(pages)
    {
        for (var index=0; index < size(pages); index +=1) {
            if (index > 0)
                pages[index]._previousPage = pages[index - 1];
        
            if (index < (size(pages) - 1))
                pages[index]._nextPage = pages[index + 1];
        }
    }, 
};


reload_CDU_pages = func 
{    
    debug.dump('loading CDU pages');
    
    cdu.displayPage(nil, 0); # force existing page to be undisplayed cleanly
    
    # make the cdu instance available inside the module namespace
    # we are going to load into.
    # for a reload this also wipes the existing namespace, which we want
    globals['cdu_NS'] = { cdu: cdu, CDU:CDU };

    var settings = props.globals.getNode('/instrumentation/cdu/settings');
    foreach (var path; settings.getChildren('page')) {        
        # resolve the path in FG_ROOT, and --fg-aircraft dir, etc
        var abspath = resolvepath(path.getValue());
        if (io.stat(abspath) == nil) {
            debug.dump('CDU page not found:', path.getValue(), abspath);
            continue;
        }

        # load pages code into a seperate namespace which we defined above
        # also means we can clean out that namespace later
        io.load_nasal(abspath, 'cdu_NS');
    }

    cdu.displayPageByTag(getprop('/instrumentation/cdu/settings/boot-page'));
};

addcommand('cdu-reload', reload_CDU_pages);

setlistener("/nasal/canvas/loaded", func 
{
    # create base CDU
    cdu = CDU.new('/instrumentation/cdu', {"node": "CDUscreen"});
    reload_CDU_pages();
}, 1);
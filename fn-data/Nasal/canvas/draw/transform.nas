#
# canvas.transform library
# created 12/2018 by jsb 
# based on plot2D.nas from the oscilloscope add-on by R. Leibner
#
# Contains functions to transform existing canvas elements.

var transform = {
    _xy: func(elem, uv){
        # returns [x, y]: intrinsic coords of the absolute(u, v)
        var (tx, ty) = elem.getTranslation();
        var (sx, sy) = elem.getScale();
        return [(uv[0] - tx)/sx, (uv[1] - ty)/sy];
    },
        
    move: func(elem, dx, dy){
        # moves the element <dx, dy> pixels  position.
        var (tx, ty) =  elem.getTranslation();
        elem.setTranslation(tx + dx, ty + dy);
    },

    rotate: func(elem, deg, center){
        # rotates the element <deg> degrees around <center>.
        var c = me._xy(elem, center);
        elem.setCenter(c).setRotation(-deg * D2R);
    },

    flipX: func(elem, xaxis = 0) {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (xmin, ymin, xmax, ymax) = elem.getTightBoundingBox();
        if (xaxis == 0) {
            xaxis = tx + sx*(xmax + xmin)/2;
        }
        elem.setScale(-sx, sy);
        elem.setTranslation(2*xaxis - tx, ty);
        return elem;
    },

    flipY: func(elem, yaxis = 0) {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (xmin, ymin, xmax, ymax) = elem.getTightBoundingBox();
        if (yaxis == 0) {
            yaxis = ty + sy*(ymax + ymin)/2;
        }
        elem.setScale(sx, -sy);
        elem.setTranslation(tx, 2*yaxis - ty);
        return elem;
    },

    # Aligns the element, moving it horizontaly to ref.
    # params:
    #   elem        element to be moved.
    #   ref         reference may be an integer or another element.
    #   alignment   as string: may be 'left-left', 'left-center', 'left-right',
    #                                 'center-left', 'center-center', 'center-right',
    #                                 'right-left', 'right-center', 'right-right'.
    #               If ref is a single number, the 2nd word is ignored.
    alignX: func(elem, ref, alignment) {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (xmin, ymin, xmax, ymax) = elem.getTightBoundingBox();
        var a = split('-', alignment)[0];
        var x = a == 'left' ? xmin : a == 'right' ? Xmax : (xmin + xmax)/2;
        if(typeof(ref) == 'scalar') var uRef = ref;
        else {
            ref.updateCenter();
            var (sRx, sRy) = ref.getScale();
            var (tRx, tRy) = ref.getTranslation();
            var (xmin, ymin, xmax, ymax) = ref.getTightBoundingBox();
            var aR = split('-', alignment)[1];
            var uRef = aR =='left' ? tRx+sRx*xmin : aR =='right' ? tRx+sRx*xmax : tRx+sRx*(xmin+xmax)/2;
        }
        elem.setTranslation(uRef-x*sx, ty);
        return elem;
    },

    # Aligns the element, moving it vertically to ref.
    # params:
    #   elem        element to be moved.
    #   ref         reference may be an integer or another element.
    #   alignment   as string: may be 'top-top', 'top-center', 'top-bottom',
    #                                 'center-top', 'center-center', 'center-bottom',
    #                                 'bottom-top', 'bottom-center', 'bottom-bottom'.
    #               text elements also accept     'baseline' as reference.
    #               If ref is a single number, the 2nd word is ignored.
    alignY: func(elem, ref, alignment) {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (Xmin, Ymin, Xmax, Ymax) = elem.getTightBoundingBox();
        var a = split('-', alignment)[0];
        var y = a == 'top' ? Ymin : a == 'bottom' ? Ymax : (Ymin+Ymax)/2;
        if(typeof(ref) =='scalar') var vRef = ref;
        else {
            ref.updateCenter();
            var (sRx, sRy) = ref.getScale();
            var (tRx, tRy) = ref.getTranslation();
            var (Xmin, Ymin, Xmax, Ymax) = ref.getTightBoundingBox();
            var aR = split('-', alignment)[1];
            var vRef = aR =='top' ? tRy+sRy*Ymin : aR =='bottom' ? tRy+sRy*Ymax : tRy+sRy*(Ymin+Ymax)/2;
        }
        elem.setTranslation(tx, vRef-y*sy);
        return elem;
    },

    # center as [x,y] in pixels, otherwise in place
    rotate180: func(elem, center = nil) {
        if(center == nil){
            me.flipX(elem);
            me.flipY(elem);
        } 
        else {
            me.flipX(elem, center[0]);
            me.flipY(elem, center[1]);
        }
        return elem;
    },

    # Stretch element horizontally
    # params:
    # elem        element to be stretched.
    # factor      the <new-width>/<old-width> ratio.
    # ref         the relative point to keep inplace. May be 'left', 'center' or 'right'.
    scaleX: func(elem, factor, ref = 'left') {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (xmin, ymin, xmax, ymax) = elem.getTightBoundingBox();
        var x = (ref == 'left') ? xmin : (ref == 'right') ? xmax : (xmin + xmax)/2;
        var u = tx + x*sx;
        print("scaleX: "~factor~"; sx="~sx~" sy="~sy~" tx="~tx~" ty="~ty,
            sprintf(" BB %1.3e, %1.3e, %1.3e, %1.3e, ", xmin, ymin, xmax ,ymax), 
            " u="~u);
        elem.setScale(sx*factor, sy);
        elem.setTranslation(u-x*sx*factor, ty);
        return elem;
    },

    # strech element vertically 
    # params:
    # elem        element to be stretched.
    # factor      the <new-height>/<old-height> ratio.
    # ref         the relative point to keep inplace. May be 'top', 'center' or 'bottom'.
    scaleY: func(elem, factor, ref = 'top') {
        elem.updateCenter();
        var (sx, sy) = elem.getScale();
        var (tx, ty) = elem.getTranslation();
        var (xmin, ymin, xmax, ymax) = elem.getTightBoundingBox();
        var y = (ref =='top') ? ymin : (ref == 'bottom') ? ymax : (ymin + ymax)/2;
        var v = ty + y*sy;
        elem.setScale(sx, sy*factor);
        elem.setTranslation(tx, v-y*sy*factor);
        return elem;
    },

    # factors     as [Xfactor, Yfactor] .
    # ref         the relative point to keep inplace:
    #             may be 'left-top', 'left-center', 'left-bottom',
    #                    'center-top', 'center-center', 'center-bottom',
    #                    'right-top', 'right-center', 'right-bottom'.
    resize: func(elem, factors, ref = 'left-top') {
        me.scaleX(elem, factors[0], split('-', ref)[0]);
        me.scaleY(elem, factors[1], split('-', ref)[1]);
        return elem;
    },
};

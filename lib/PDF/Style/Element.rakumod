use v6;

use PDF::Style;

class PDF::Style::Element
    is PDF::Style {
    use PDF::Content;
    use PDF::Content::Canvas;
    use PDF::Content::Color :&color, :&gray;
    use PDF::Content::XObject;
    use CSS::Properties;
    use CSS::Stylesheet;
    use CSS::Box :Edges;
    use CSS::Units :Lengths, :pt;
    use PDF::Tags::Elem;
    use PDF::Style::Util :&measure, :&css-height, :&css-width;
    has PDF::Tags::Elem $.tag;

    method !bbox {
        my Numeric @b[4] = $.box.border.list;
        [@b[Left] - $.left, @b[Bottom] - $.bottom, @b[Right] - $.left, @b[Top] - $.bottom];
    }

    method !xobject(|c) {
        my @BBox = self!bbox;
        my PDF::Content::Canvas \image .= xobject-form: :@BBox;
        my $gfx = image.gfx;
        self.graphics: :$gfx, {
            self!render($_, |c);
        }
        image.finish;
        image;
    }

    # containerized rendering when xobjects are preferred
    method xobject(|c) {
        # apply opacity to an image group as a whole
        my PDF::Content::Canvas:D $xobject = self!xobject(|c);
        my $opacity = $.css.opacity.Num;

        if $opacity < 1 {
           # need to box it, to apply transparency.
           my @BBox = self!bbox;
           my PDF::Content::Canvas:D $outer .= xobject-form: :@BBox;
           $outer.graphics: {
               .FillAlpha = .StrokeAlpha = $opacity;
               .do($xobject, 0, 0);
           }
           $xobject = $outer;
        }
        $xobject;
    }

    method !mark($gfx, &action) {
        with $!tag {
            .mark($gfx, &action);
        }
        else {
            action();
        }
    }

    # non-containerized rendering.
    method render(
        $x = $.left, $y = $.bottom,
        PDF::Content :$gfx = $.gfx,
    |c) {
        self!mark: $gfx, {

            if ! self.isa("PDF::Style::Element::Text") && $.css.opacity.Num < 1 {
               # need to box it, to apply transparency.
                my @BBox = self!bbox;
                my PDF::Content::Canvas:D $xobject .= xobject-form: :@BBox;

                self.graphics: :gfx($xobject.gfx), {
                    self!render($_, |c);
                }
               $gfx.do: $xobject, $x, $y, :valign<bottom>;
            }
            else {
                self.graphics: :$gfx, {
                    .transform: :translate[$x, $y];
                    self!render($_, |c);
                }
            }
        }
    }

    method !render(PDF::Content $_) {
        self.style-box($_);
        self.render-element($_);
    }

    #| create and position content within a containing box
    method place-element(
        CSS::Properties :$css!,
        :&build-content = sub (|c) {},
        CSS::Box :$container!,
        PDF::Tags::Elem :$tag,
        PDF::Content :$gfx,
    ) {
        my $ref    = $container.width;
        my $top    = measure($container.css, $css.top, :$ref);
        my $bottom = measure($container.css, $css.bottom, :$ref);
        my $height = css-height($container, $css, :$ref);

        my \height-max = $height // do {
            my $margin = sum <padding-top padding-bottom border-top-width border-bottom-width>.map: {
                $container.measure($css."$_"(), :$ref) // 0
            }
            $container.height - ($top//0) - ($bottom//0) - $margin;
        }

        my $left  = measure($container.css, $css.left, :$ref);
        my $right = measure($container.css, $css.right, :$ref);
        my $width = css-width($container, $css, :$ref);

        my \width-max = $width // do {
            my $margin = sum <padding-left padding-right border-left-width border-right-width>.map: {
                $container.measure($css."$_"(), :$ref) // 0
            }
            $container.width - ($left//0) - ($right//0) - $margin;
        }

        my subset ContentType where 'html-canvas'|'image'|'text';
        my (ContentType $type, $content) = (.key, .value)
            with &build-content( :width(width-max), :height(height-max) );

        $width //= width-max if $left.defined && $right.defined;
        $width //= .content-width with $content;
        with $container.measure($css.min-width, :$ref) -> \min {
            $width = min if min > $width
        }

        $height //= .content-height with $content;
        with $container.measure($css.min-height, :$ref) -> \min {
            $height = min if min > $height
        }

        my Bool \from-left = $left.defined;
        unless from-left {
            $left = $right.defined
                ?? $container.width - $right - $width
                !! 0;
        }

        my Bool \from-top = $top.defined;
        unless from-top {
            $top = $bottom.defined
                ?? $container.height - $bottom - $height
                !! 0;
        }

        #| adjust from PDF coordinates. Shift origin from top-left to bottom-left;
        my \pdf-top = $container.height - $top;
        my $em = $container.em;
        my $ex = $container.ex;
        my $vw = $container.viewport-width;
        my $vh = $container.viewport-height;
        $css.reference-width = $ref;
        my \elem = self.new: :$css, :$gfx, :$left, :top(pdf-top), :$width, :$height, :$em, :$ex, :$vw, :$vh, :$tag, |($type => $content);

        # reposition to outside of border
        my Numeric @content-box[4] = elem.Array.list;
        my Numeric @border-box[4]  = elem.border.list;
        my \dx = from-left
               ?? @content-box[Left]  - @border-box[Left]
               !! @content-box[Right] - @border-box[Right];
        my \dy = from-top
               ?? @content-box[Top]    - @border-box[Top]
               !! @content-box[Bottom] - @border-box[Bottom];

        elem.translate(dx, dy);
        elem;
    }

    method element(|c) {
        require PDF::Style::Body;
        state $body //= PDF::Style::Body.new: :width(1684pt), :height(2381pt);
        $body.element(|c);
    }

    method html-escape(Str $_) {
        .trans:
            /\&/ => '&amp;',
            /\</ => '&lt;',
            /\>/ => '&gt;',
            /\"/ => '&quot;',
    }

}

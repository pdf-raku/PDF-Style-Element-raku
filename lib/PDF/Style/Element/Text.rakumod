use v6;

use PDF::Style::Element;

class PDF::Style::Element::Text
    is PDF::Style::Element {

    use CSS::Box;
    use CSS::Properties;
    use PDF::Style::Font;
    use PDF::Style::Basic :&text-box-options;

    use PDF::Content::Text::Box;
    use PDF::Content::FontObj;
    has PDF::Content::Text::Box $.text;
    use PDF::Tags::Elem;

    method place-element( Str:D :$text!,
                          CSS::Properties :$css!,
                          CSS::Box :$container!,
                          PDF::Tags::Elem :$tag,
        ) {
        my PDF::Style::Font $font = $container.font;
        $font.css = $css;
        my Numeric $ref = $container.width;
        my %opt = text-box-options( :$font, :$css, :$ref);
        my &build-content = sub (|c) {
            text => PDF::Content::Text::Box.new( :$text, |%opt, |c);
        };
        nextwith(:$css, :&build-content, :$container, :$tag);
    }

    method render-element($gfx) {
        with $!text -> \text {
            my $top = $.top - $.bottom;
            $gfx.print(text, :position[ :left(0), :$top]);
        }
    }

    method !div(CSS::Properties $css, Str $text) {
        my $style-att = $css
            ?? $.html-escape($css.write).fmt: ' style="%s"'
            !! '';
        '<div%s>%s</div>'.sprintf($style-att, $text);
    }

    method html {
        my $css = $.css;

        my $text = do with $!text {
            $.html-escape(.text);
        }
        else {
            ''
        }

        given $css.vertical-align -> $valign {
            unless $valign eq 'baseline' {
                # hah, we're verically aligning a div!
                # wrap content in sized div for vertical align to take affect
                my @size-props = <top left bottom right width height position>.grep: {$css.property-exists($_)};
                if @size-props {
                    my CSS::Properties:D $inner = $css.clone;
                    $css = CSS::Properties.copy($inner, :properties(@size-props));
                    $css.display = 'table';
                    $inner.delete: @size-props;
                    $inner.display = 'table-cell';
                    $text = self!div($inner, $text);
                }
            }
        }

        self!div($css, $text);
    }

}

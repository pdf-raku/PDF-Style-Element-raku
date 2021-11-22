use v6;
use Test;
plan 1;

use PDF::Style::Body;
use PDF::Class;
use CSS::Properties;
use CSS::Units :ops, :pt;

my PDF::Style::Body $body .= new;

my PDF::Class $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;

my CSS::Properties() $css = "font-family:Vera; font-weight: 200;width:250pt; height:80pt; border: 1px solid green; padding:2pt; opacity:.8";

my $text = $css.Str ~ ' Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt';

$css.left = '50pt';
$css.bottom = '700pt';

my $text-elem = $body.element( :$text, :$css);
does-ok $text-elem.xobject, PDF::Content::XObject;
.gfx.do(.xobject, .left, .bottom) with $text-elem;;

my Str $image = "t/images/snoopy-happy-dance.jpg";
$css.delete("height");
my $image-elem = $body.element(:$image, :$css);
.gfx.do(.xobject, .left, .bottom - $image-elem.height('padding'))
    with $image-elem;

$pdf.save-as: "t/do.pdf";

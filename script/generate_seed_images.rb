# Generates the cartoon placeholder product images used by db/seeds.rb.
#
#   ruby script/generate_seed_images.rb
#
# Each image is a flat-color clothing shape drawn as SVG, then converted by
# vips + ImageMagick into a small 400x400, 16-color PNG in db/seeds/images/.
# PNG is used instead of SVG because Active Storage can't make variants of SVGs.

require "fileutils"
require "tmpdir"

OUT_DIR = File.expand_path("../db/seeds/images", __dir__)
OUTLINE = "#2b2b2b"

# Base garment outlines, drawn on a 200x200 canvas.
SHAPES = {
  shirt:  "M70 40 L48 50 L28 82 L50 95 L60 80 L60 168 L140 168 L140 80 L150 95 L172 82 L152 50 L130 40 Q100 62 70 40 Z",
  jacket: "M70 36 L46 46 L32 152 L54 155 L62 88 L62 170 L138 170 L138 88 L146 155 L168 152 L154 46 L130 36 Q100 56 70 36 Z",
  vest:   "M70 36 L56 44 L58 170 L142 170 L144 44 L130 36 Q100 72 70 36 Z",
  pants:  "M64 28 L136 28 L148 176 L110 176 L100 78 L90 176 L52 176 Z",
  shorts: "M58 50 L142 50 L154 142 L108 142 L100 96 L92 142 L46 142 Z",
  beanie: "M48 132 Q48 52 100 52 Q152 52 152 132 Z",
  cap:    "M52 128 Q56 62 100 62 Q144 62 148 128 Z",
  scarf:  "M58 48 Q100 30 142 48 L142 76 Q100 60 58 76 Z M104 68 L132 68 L136 168 L108 168 Z",
  belt:   "M16 88 L184 88 L184 112 L16 112 Z"
}

# Small extras that tell similar items apart. `c` is a darker accent color.
def detail(kind, c)
  case kind
  when :plain_tee  then ""
  when :graphic    then %(<circle cx="100" cy="110" r="22" fill="#{c}"/><path d="M90 110 L100 96 L110 110 Z" fill="#fff"/>)
  when :polo       then %(<path d="M86 42 L100 64 L114 42" fill="none" stroke="#{OUTLINE}" stroke-width="3"/><circle cx="100" cy="72" r="3" fill="#{c}"/><circle cx="100" cy="84" r="3" fill="#{c}"/>)
  when :oxford     then %(<path d="M78 42 L100 60 L122 42 L110 38 L100 50 L90 38 Z" fill="#fff" stroke="#{OUTLINE}" stroke-width="2"/>) +
                        (70..150).step(20).map { |y| %(<circle cx="100" cy="#{y}" r="3" fill="#{c}"/>) }.join
  when :flannel    then (75..160).step(18).map { |y| %(<path d="M60 #{y} L140 #{y}" stroke="#{c}" stroke-width="5"/>) }.join +
                        (72..140).step(22).map { |x| %(<path d="M#{x} 55 L#{x} 168" stroke="#{c}" stroke-width="5"/>) }.join
  when :denim      then %(<path d="M100 50 L100 170" stroke="#{c}" stroke-width="3"/><rect x="70" y="80" width="20" height="16" fill="none" stroke="#{c}" stroke-width="3"/><rect x="110" y="80" width="20" height="16" fill="none" stroke="#{c}" stroke-width="3"/>)
  when :hoodie     then %(<path d="M70 36 Q100 6 130 36 Q100 56 70 36 Z" fill="#{c}" stroke="#{OUTLINE}" stroke-width="3"/><rect x="78" y="128" width="44" height="26" rx="6" fill="#{c}"/>)
  when :sweater    then %(<path d="M62 100 L74 88 L86 100 L98 88 L110 100 L122 88 L138 100" fill="none" stroke="#{c}" stroke-width="5"/><rect x="62" y="160" width="76" height="10" fill="#{c}"/>)
  when :raincoat   then %(<path d="M68 38 Q100 0 132 38 Q100 50 68 38 Z" fill="#{c}" stroke="#{OUTLINE}" stroke-width="3"/>) +
                        (70..150).step(26).map { |y| %(<rect x="96" y="#{y}" width="8" height="5" fill="#{OUTLINE}"/>) }.join
  when :bomber     then %(<path d="M100 48 L100 170" stroke="#{c}" stroke-width="3"/><rect x="62" y="160" width="76" height="10" fill="#{c}"/><rect x="32" y="146" width="22" height="9" fill="#{c}"/><rect x="146" y="146" width="22" height="9" fill="#{c}"/>)
  when :cardigan   then %(<path d="M100 60 L100 170" stroke="#{OUTLINE}" stroke-width="3"/>) +
                        (80..160).step(20).map { |y| %(<circle cx="108" cy="#{y}" r="4" fill="#{c}"/>) }.join
  when :puffer     then (68..160).step(22).map { |y| %(<path d="M58 #{y} L142 #{y}" stroke="#{c}" stroke-width="4"/>) }.join +
                        %(<path d="M100 60 L100 170" stroke="#{OUTLINE}" stroke-width="3"/>)
  when :chinos     then %(<rect x="64" y="28" width="72" height="12" fill="#{c}"/><path d="M72 46 Q80 60 92 50" fill="none" stroke="#{c}" stroke-width="3"/><path d="M128 46 Q120 60 108 50" fill="none" stroke="#{c}" stroke-width="3"/>)
  when :sweatpants then %(<rect x="64" y="28" width="72" height="12" fill="#{c}"/><path d="M96 40 L92 58 M104 40 L108 58" stroke="#{OUTLINE}" stroke-width="3"/><rect x="54" y="164" width="36" height="12" fill="#{c}"/><rect x="110" y="164" width="36" height="12" fill="#{c}"/>)
  when :linen      then %(<rect x="64" y="28" width="72" height="12" fill="#{c}"/><path d="M80 50 L74 170 M120 50 L126 170" stroke="#{c}" stroke-width="2"/>)
  when :cargo      then %(<rect x="58" y="50" width="84" height="12" fill="#{c}"/><rect x="54" y="92" width="24" height="26" fill="#{c}" stroke="#{OUTLINE}" stroke-width="2"/><rect x="122" y="92" width="24" height="26" fill="#{c}" stroke="#{OUTLINE}" stroke-width="2"/>)
  when :beanie     then %(<rect x="42" y="124" width="116" height="28" rx="6" fill="#{c}" stroke="#{OUTLINE}" stroke-width="3"/><circle cx="100" cy="44" r="14" fill="#{c}" stroke="#{OUTLINE}" stroke-width="3"/>)
  when :cap        then %(<path d="M100 124 L178 124 Q182 142 150 142 L100 136 Z" fill="#{c}" stroke="#{OUTLINE}" stroke-width="3"/><circle cx="100" cy="62" r="6" fill="#{c}" stroke="#{OUTLINE}" stroke-width="2"/>)
  when :scarf      then %(<path d="M108 168 L108 180 M116 168 L116 180 M124 168 L124 180 M132 168 L132 180" stroke="#{OUTLINE}" stroke-width="3"/><path d="M106 110 L134 110 M107 135 L135 135" stroke="#{c}" stroke-width="6"/>)
  when :belt       then %(<rect x="36" y="80" width="34" height="40" rx="4" fill="none" stroke="#{c}" stroke-width="6"/><path d="M53 100 L80 100" stroke="#{c}" stroke-width="4"/>) +
                        (110..170).step(15).map { |x| %(<circle cx="#{x}" cy="100" r="3" fill="#{OUTLINE}"/>) }.join
  end
end

# name => [base shape, detail, main color, accent color, background color]
CATALOG = {
  "T-Shirt"       => [ :shirt,  :plain_tee,  "#e74c3c", "#a93226", "#fdecea" ],
  "Graphic Tee"   => [ :shirt,  :graphic,    "#34495e", "#f1c40f", "#eaf2f8" ],
  "Polo Shirt"    => [ :shirt,  :polo,       "#27ae60", "#145a32", "#e9f7ef" ],
  "Oxford Shirt"  => [ :shirt,  :oxford,     "#85c1e9", "#1f618d", "#f4f6f7" ],
  "Flannel Shirt" => [ :shirt,  :flannel,    "#c0392b", "#641e16", "#fef5e7" ],
  "Denim Jacket"  => [ :jacket, :denim,      "#5d8aa8", "#f5cba7", "#ebf5fb" ],
  "Hoodie"        => [ :jacket, :hoodie,     "#8e44ad", "#5b2c6f", "#f5eef8" ],
  "Wool Sweater"  => [ :jacket, :sweater,    "#d35400", "#fdebd0", "#fbeee6" ],
  "Rain Coat"     => [ :jacket, :raincoat,   "#f4d03f", "#b7950b", "#e8f8f5" ],
  "Bomber Jacket" => [ :jacket, :bomber,     "#556b2f", "#e67e22", "#f2f3f4" ],
  "Cardigan"      => [ :jacket, :cardigan,   "#d7bde2", "#6c3483", "#fdfefe" ],
  "Puffer Vest"   => [ :vest,   :puffer,     "#e67e22", "#a04000", "#eaf2f8" ],
  "Chinos"        => [ :pants,  :chinos,     "#c8a165", "#7e5109", "#fef9e7" ],
  "Sweatpants"    => [ :pants,  :sweatpants, "#95a5a6", "#566573", "#f4f6f7" ],
  "Linen Pants"   => [ :pants,  :linen,      "#f5f0e1", "#b9a77f", "#e8f6f3" ],
  "Cargo Shorts"  => [ :shorts, :cargo,      "#7d8c5a", "#4d5637", "#fef5e7" ],
  "Beanie"        => [ :beanie, :beanie,     "#16a085", "#0e6655", "#fdedec" ],
  "Baseball Cap"  => [ :cap,    :cap,        "#2e86c1", "#1b4f72", "#fef9e7" ],
  "Scarf"         => [ :scarf,  :scarf,      "#c0392b", "#f7dc6f", "#ebf5fb" ],
  "Leather Belt"  => [ :belt,   :belt,       "#6e2c00", "#d4ac0d", "#fdf2e9" ]
}

def svg_for(shape, detail_kind, main, accent, bg)
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 200 200">
      <rect width="200" height="200" fill="#{bg}"/>
      <path d="#{SHAPES.fetch(shape)}" fill="#{main}" stroke="#{OUTLINE}" stroke-width="3" stroke-linejoin="round"/>
      #{detail(detail_kind, accent)}
    </svg>
  SVG
end

def slug(name) = name.downcase.gsub(/[^a-z0-9]+/, "-").delete_suffix("-")

FileUtils.mkdir_p(OUT_DIR)

Dir.mktmpdir do |tmp|
  CATALOG.each do |name, (shape, detail_kind, main, accent, bg)|
    svg_path = File.join(tmp, "#{slug(name)}.svg")
    png_path = File.join(OUT_DIR, "#{slug(name)}.png")
    File.write(svg_path, svg_for(shape, detail_kind, main, accent, bg))

    # Render with vips (librsvg draws strokes correctly), then shrink to a
    # 16-color palette PNG with no dithering or metadata to keep each file a few KB.
    raw_path = File.join(tmp, "#{slug(name)}.raw.png")
    system("vips", "copy", svg_path, raw_path, exception: true)
    system("magick", raw_path, "-strip", "+dither", "-colors", "16", "PNG8:#{png_path}", exception: true)
    puts "#{File.basename(png_path).ljust(20)} #{(File.size(png_path) / 1024.0).round(1)} KB"
  end
end

# https://github.com/jheinen/GR.jl - significant contributions by @jheinen

import GR
export GR

const gr_linetypes = (auto = 1, solid = 1, dash = 2, dot = 3, dashdot = 4, dashdotdot = -1)
const gr_fill_styles = ((/) = 9, (\) = 10, (|) = 7, (-) = 8, (+) = 11, (x) = 6)
const gr_arrowstyles = (
    simple = 1,
    hollow = 3,
    filled = 4,
    triangle = 5,
    filledtriangle = 6,
    closed = 6,
    open = 5,
)
const gr_markertypes = (
    auto = 1,
    pixel = 1,
    none = -1,
    circle = -1,
    rect = -7,
    diamond = -13,
    utriangle = -3,
    dtriangle = -5,
    ltriangle = -18,
    rtriangle = -17,
    pentagon = -21,
    hexagon = -22,
    heptagon = -23,
    octagon = -24,
    cross = 2,
    xcross = 5,
    (+) = 2,
    x = 5,
    star4 = -25,
    star5 = -26,
    star6 = -27,
    star7 = -28,
    star8 = -29,
    vline = -30,
    hline = -31,
)
const gr_haligns = (
    left = GR.TEXT_HALIGN_LEFT,
    hcenter = GR.TEXT_HALIGN_CENTER,
    center = GR.TEXT_HALIGN_CENTER,
    right = GR.TEXT_HALIGN_RIGHT,
)
const gr_valigns = (
    top = GR.TEXT_VALIGN_TOP,
    vcenter = GR.TEXT_VALIGN_HALF,
    center = GR.TEXT_VALIGN_HALF,
    bottom = GR.TEXT_VALIGN_BOTTOM,
)
const gr_projections = (auto = 1, ortho = 1, orthographic = 1, persp = 2, perspective = 2)

const gr_font_family = Dict(
    # compat
    "times" => 101,
    "helvetica" => 105,
    "courier" => 109,
    "bookman" => 114,
    "newcenturyschlbk" => 118,
    "avantgarde" => 122,
    "palatino" => 126,
    "serif-roman" => 232,
    "sans-serif" => 233,
    # https://gr-framework.org/fonts.html
    "times roman" => 101,
    "times italic" => 102,
    "times bold" => 103,
    "times bold italic" => 104,
    "helvetica" => 105,
    "helvetica oblique" => 106,
    "helvetica bold" => 107,
    "helvetica bold oblique" => 108,
    "courier" => 109,
    "courier oblique" => 110,
    "courier bold" => 111,
    "courier bold oblique" => 112,
    "symbol" => 113,
    "bookman light" => 114,
    "bookman light italic" => 115,
    "bookman demi" => 116,
    "bookman demi italic" => 117,
    "new century schoolbook roman" => 118,
    "new century schoolbook italic" => 119,
    "new century schoolbook bold" => 120,
    "new century schoolbook bold italic" => 121,
    "avantgarde book" => 122,
    "avantgarde book oblique" => 123,
    "avantgarde demi" => 124,
    "avantgarde demi oblique" => 125,
    "palatino roman" => 126,
    "palatino italic" => 127,
    "palatino bold" => 128,
    "palatino bold italic" => 129,
    "zapf chancery medium italic" => 130,
    "zapf dingbats" => 131,
    "computer modern" => 232,
    "dejavu sans" => 233,
)

struct GRViewport{T}
    xmin::Base.RefValue{T}
    xmax::Base.RefValue{T}
    ymin::Base.RefValue{T}
    ymax::Base.RefValue{T}
end

GRViewport(xm::Number, xM::Number, ym::Number, yM::Number) =
    GRViewport(Ref(xm), Ref(xM), Ref(ym), Ref(yM))

xmin(v::GRViewport) = v.xmin[]
xmax(v::GRViewport) = v.xmax[]
ymin(v::GRViewport) = v.ymin[]
ymax(v::GRViewport) = v.ymax[]

xyminmax(v::GRViewport) = xmin(v), xmax(v), ymin(v), ymax(v)

width(v::GRViewport) = xmax(v) - xmin(v)
height(v::GRViewport) = ymax(v) - ymin(v)

xcenter(v::GRViewport) = 0.5(xmin(v) + xmax(v))
ycenter(v::GRViewport) = 0.5(ymin(v) + ymax(v))

xposition(v::GRViewport, pos) = xmin(v) + pos * width(v)
yposition(v::GRViewport, pos) = ymin(v) + pos * height(v)

# --------------------------------------------------------------------------------------
gr_is3d(st) = RecipesPipeline.is3d(st)

gr_color(c, ::Type) = gr_color(RGBA(c), RGB)
gr_color(c) = gr_color(c, color_type(c))
gr_color(c, ::Type{<:AbstractRGB}) = UInt32(
    round(UInt, clamp(255alpha(c), 0, 255)) << 24 +
    round(UInt, clamp(255blue(c), 0, 255)) << 16 +
    round(UInt, clamp(255green(c), 0, 255)) << 8 +
    round(UInt, clamp(255red(c), 0, 255)),
)
gr_color(c, ::Type{<:AbstractGray}) =
    let g = round(UInt, clamp(255gray(c), 0, 255)),
        α = round(UInt, clamp(255alpha(c), 0, 255))

        UInt32(α << 24 + g << 16 + g << 8 + g)
    end

set_RGBA_alpha(alpha, c::RGBA) = RGBA(red(c), green(c), blue(c), alpha)
set_RGBA_alpha(alpha::Nothing, c::RGBA) = c

function gr_getcolorind(c)
    gr_set_transparency(float(alpha(c)))
    convert(Int, GR.inqcolorfromrgb(red(c), green(c), blue(c)))
end

gr_set_linecolor(c) = GR.setlinecolorind(gr_getcolorind(_cycle(c, 1)))
gr_set_fillcolor(c) = GR.setfillcolorind(gr_getcolorind(_cycle(c, 1)))
gr_set_markercolor(c) = GR.setmarkercolorind(gr_getcolorind(_cycle(c, 1)))
gr_set_bordercolor(c) = GR.setbordercolorind(gr_getcolorind(_cycle(c, 1)))
gr_set_textcolor(c) = GR.settextcolorind(gr_getcolorind(_cycle(c, 1)))
gr_set_transparency(α::Real) = GR.settransparency(clamp(α, 0, 1))
gr_set_transparency(::Nothing) = GR.settransparency(1)
gr_set_transparency(c, α) = gr_set_transparency(α)
gr_set_transparency(c::Colorant, ::Nothing) = gr_set_transparency(c)
gr_set_transparency(c::Colorant) = GR.settransparency(alpha(c))

gr_set_arrowstyle(style::Symbol) = GR.setarrowstyle(get(gr_arrowstyles, style, 1))

gr_set_fillstyle(::Nothing) = GR.setfillintstyle(GR.INTSTYLE_SOLID)
function gr_set_fillstyle(s::Symbol)
    GR.setfillintstyle(GR.INTSTYLE_HATCH)
    GR.setfillstyle(get(gr_fill_styles, s, 9))
    nothing
end

# https://gr-framework.org/python-gr.html?highlight=setprojectiontype#gr.setprojectiontype
# PROJECTION_DEFAULT      0 default
# PROJECTION_ORTHOGRAPHIC 1 orthographic
# PROJECTION_PERSPECTIVE  2 perspective
# we choose to unify backends by using a default `orthographic` proj when `:auto`
gr_set_projectiontype(sp) = GR.setprojectiontype(gr_projections[sp[:projection_type]])

# --------------------------------------------------------------------------------------

# draw line segments, splitting x/y into contiguous/finite segments
# note: this can be used for shapes by passing func `GR.fillarea`
function gr_polyline(x, y, func = GR.polyline; arrowside = :none, arrowstyle = :simple)
    iend = 0
    n = length(x)
    while iend < n - 1
        istart = -1  # set istart to the first index that is finite
        for j in (iend + 1):n
            if ok(x[j], y[j])
                istart = j
                break
            end
        end
        if istart > 0
            iend = -1  # iend is the last finite index
            for j in (istart + 1):n
                if ok(x[j], y[j])
                    iend = j
                else
                    break
                end
            end
        end
        # if we found a start and end, draw the line segment, otherwise we're done
        if istart > 0 && iend > 0
            func(x[istart:iend], y[istart:iend])
            if arrowside in (:head, :both)
                gr_set_arrowstyle(arrowstyle)
                GR.drawarrow(x[iend - 1], y[iend - 1], x[iend], y[iend])
            end
            if arrowside in (:tail, :both)
                gr_set_arrowstyle(arrowstyle)
                GR.drawarrow(x[istart + 1], y[istart + 1], x[istart], y[istart])
            end
        else
            break
        end
    end
end

function gr_polyline3d(x, y, z, func = GR.polyline3d)
    iend = 0
    n = length(x)
    while iend < n - 1
        # set istart to the first index that is finite
        istart = -1
        for j in (iend + 1):n
            if ok(x[j], y[j], z[j])
                istart = j
                break
            end
        end

        if istart > 0
            # iend is the last finite index
            iend = -1
            for j in (istart + 1):n
                if ok(x[j], y[j], z[j])
                    iend = j
                else
                    break
                end
            end
        end

        # if we found a start and end, draw the line segment, otherwise we're done
        if istart > 0 && iend > 0
            func(x[istart:iend], y[istart:iend], z[istart:iend])
        else
            break
        end
    end
end

gr_inqtext(x, y, s) = gr_inqtext(x, y, string(s))
gr_inqtext(x, y, s::AbstractString) =
    if (occursin('\\', s) || occursin("10^{", s)) &&
       match(r".*\$[^\$]+?\$.*", String(s)) === nothing
        GR.inqtextext(x, y, s)
    else
        GR.inqtext(x, y, s)
    end

gr_text(x, y, s) = gr_text(x, y, string(s))
gr_text(x, y, s::AbstractString) =
    if (occursin('\\', s) || occursin("10^{", s)) &&
       match(r".*\$[^\$]+?\$.*", String(s)) === nothing
        GR.textext(x, y, s)
    else
        GR.text(x, y, s)
    end

function gr_polaraxes(rmin::Real, rmax::Real, sp::Subplot)
    GR.savestate()
    xaxis = sp[:xaxis]
    yaxis = sp[:yaxis]

    α = 0:45:315
    a = α .+ 90
    sinf = sind.(a)
    cosf = cosd.(a)
    rtick_values, rtick_labels = get_ticks(sp, yaxis, update = false)

    # draw angular grid
    if xaxis[:grid]
        gr_set_line(
            xaxis[:gridlinewidth],
            xaxis[:gridstyle],
            xaxis[:foreground_color_grid],
            sp,
        )
        gr_set_transparency(xaxis[:foreground_color_grid], xaxis[:gridalpha])
        for i in eachindex(α)
            GR.polyline([sinf[i], 0], [cosf[i], 0])
        end
    end

    # draw radial grid
    if yaxis[:grid]
        gr_set_line(
            yaxis[:gridlinewidth],
            yaxis[:gridstyle],
            yaxis[:foreground_color_grid],
            sp,
        )
        gr_set_transparency(yaxis[:foreground_color_grid], yaxis[:gridalpha])
        for i in eachindex(rtick_values)
            r = (rtick_values[i] - rmin) / (rmax - rmin)
            (r ≤ 1 && r ≥ 0) && GR.drawarc(-r, r, -r, r, 0, 359)
        end
        GR.drawarc(-1, 1, -1, 1, 0, 359)
    end

    # prepare to draw ticks
    gr_set_transparency(1)
    GR.setlinecolorind(90)
    GR.settextalign(GR.TEXT_HALIGN_CENTER, GR.TEXT_VALIGN_HALF)

    # draw angular ticks
    if xaxis[:showaxis]
        GR.drawarc(-1, 1, -1, 1, 0, 359)
        for i in eachindex(α)
            x, y = GR.wctondc(1.1sinf[i], 1.1cosf[i])
            GR.textext(x, y, string((360 - α[i]) % 360, "^o"))
        end
    end

    # draw radial ticks
    yaxis[:showaxis] && for i in eachindex(rtick_values)
        r = (rtick_values[i] - rmin) / (rmax - rmin)
        (r ≤ 1 && r ≥ 0) && gr_text(GR.wctondc(0.05, r)..., _cycle(rtick_labels, i))
    end
    GR.restorestate()
end

# using the axis extrema and limit overrides, return the min/max value for this axis
gr_x_axislims(sp::Subplot) = axis_limits(sp, :x)
gr_y_axislims(sp::Subplot) = axis_limits(sp, :y)
gr_z_axislims(sp::Subplot) = axis_limits(sp, :z)
gr_xy_axislims(sp::Subplot) = gr_x_axislims(sp)..., gr_y_axislims(sp)...

function gr_fill_viewport(vp::GRViewport, c)
    GR.savestate()
    GR.selntran(0)
    GR.setscale(0)
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    gr_set_fillcolor(c)
    GR.fillrect(xyminmax(vp)...)
    GR.selntran(1)
    GR.restorestate()
end

gr_fill_plotarea(sp, vp::GRViewport) =
    gr_is3d(sp) || gr_fill_viewport(vp, plot_color(sp[:background_color_inside]))

# ---------------------------------------------------------

gr_nominal_size(s) = minimum(get_size(s)) / 500

# draw ONE Shape
function gr_draw_marker(series, xi, yi, zi, clims, i, msize, strokewidth, shape::Shape)
    # convert to ndc coords (percentages of window) ...
    xi, yi = if zi === nothing
        GR.wctondc(xi, yi)
    else
        gr_w3tondc(xi, yi, zi)
    end
    f = msize / sum(get_size(series))

    # ... convert back to world coordinates
    sx, sy = coords(shape)
    xs_ys = GR.ndctowc.(xi .+ sx .* f, yi .+ sy .* f)
    xs, ys = getindex.(xs_ys, 1), getindex.(xs_ys, 2)

    # draw the interior
    mc = get_markercolor(series, clims, i)
    gr_set_fill(mc)
    gr_set_transparency(mc, get_markeralpha(series, i))
    GR.fillarea(xs, ys)

    # draw the shapes
    msc = get_markerstrokecolor(series, i)
    gr_set_line(strokewidth, :solid, msc, series)
    gr_set_transparency(msc, get_markerstrokealpha(series, i))
    GR.polyline(xs, ys)
end

# draw ONE symbol marker
function gr_draw_marker(series, xi, yi, zi, clims, i, msize, strokewidth, shape::Symbol)
    GR.setborderwidth(strokewidth)
    gr_set_bordercolor(get_markerstrokecolor(series, i))
    gr_set_markercolor(get_markercolor(series, clims, i))
    gr_set_transparency(get_markeralpha(series, i))
    GR.setmarkertype(gr_markertypes[shape])
    GR.setmarkersize(0.3msize / gr_nominal_size(series))
    if zi === nothing
        GR.polymarker([xi], [yi])
    else
        GR.polymarker3d([xi], [yi], [zi])
    end
end

# ---------------------------------------------------------

function gr_set_line(lw, style, c, s)  # s can be Subplot or Series
    GR.setlinetype(gr_linetypes[style])
    GR.setlinewidth(get_thickness_scaling(s) * max(0, lw / gr_nominal_size(s)))
    gr_set_linecolor(c)
end

gr_set_fill(c) = (gr_set_fillcolor(c); GR.setfillintstyle(GR.INTSTYLE_SOLID); nothing)

# this stores the conversion from a font pointsize to "percentage of window height"
# (which is what GR uses). `s` can be a Series, Subplot or Plot
gr_point_mult(s) = 1.5get_thickness_scaling(s) * px / pt / maximum(get_size(s))

# set the font attributes.
function gr_set_font(
    f::Font,
    s;
    halign = f.halign,
    valign = f.valign,
    color = f.color,
    rotation = f.rotation,
)
    family = lowercase(f.family)
    GR.setcharheight(gr_point_mult(s) * f.pointsize)
    GR.setcharup(sind(-rotation), cosd(-rotation))
    haskey(gr_font_family, family) && GR.settextfontprec(
        gr_font_family[family],
        gr_font_family[family] ≥ 200 ? 3 : GR.TEXT_PRECISION_STRING,
    )
    gr_set_textcolor(plot_color(color))
    GR.settextalign(gr_haligns[halign], gr_valigns[valign])
end

function gr_w3tondc(x, y, z)
    xw, yw, _ = GR.wc3towc(x, y, z)
    GR.wctondc(xw, yw)  # x, y
end

# --------------------------------------------------------------------------------------
# viewport plot area

function gr_viewport_from_bbox(sp::Subplot{GRBackend}, bb::BoundingBox, w, h, vp_canvas)
    viewport = GRViewport(
        vp_canvas.xmax[] * (left(bb) / w),
        vp_canvas.xmax[] * (right(bb) / w),
        vp_canvas.ymax[] * (1 - bottom(bb) / h),
        vp_canvas.ymax[] * (1 - top(bb) / h),
    )
    hascolorbar(sp) && (viewport.xmax[] -= 0.1(1 + 0.5gr_is3d(sp)))
    viewport
end

# change so we're focused on the viewport area
gr_set_viewport_cmap(sp::Subplot, vp) = GR.setviewport(
    xmax(vp) + (gr_is3d(sp) ? 0.07 : 0.02),
    xmax(vp) + (gr_is3d(sp) ? 0.10 : 0.05),
    ymin(vp),
    ymax(vp),
)

function gr_set_viewport_polar(vp)
    x_min, x_max, y_min, y_max = xyminmax(vp)
    y_max -= 0.05(x_max - x_min)
    x_ctr = 0.5(x_min + x_max)
    y_ctr = 0.5(y_min + y_max)
    r = 0.5 * NaNMath.min(x_max - x_min, y_max - y_min)
    GR.setviewport(x_ctr - r, x_ctr + r, y_ctr - r, y_ctr + r)
    GR.setwindow(-1, 1, -1, 1)
    r
end

struct GRColorbar
    gradients
    fills
    lines
    GRColorbar() = new([], [], [])
end

function gr_update_colorbar!(cbar::GRColorbar, series::Series)
    (style = colorbar_style(series)) === nothing && return
    list =
        style == cbar_gradient ? cbar.gradients :
        style == cbar_fill ? cbar.fills :
        style == cbar_lines ? cbar.lines : error("Unknown colorbar style: $style.")
    push!(list, series)
end

function gr_contour_levels(series::Series, clims)
    levels = collect(contour_levels(series, clims))
    # GR implicitly uses the maximal z value as the highest level
    isfilledcontour(series) && pop!(levels)
    levels
end

function gr_colorbar_colors(series::Series, clims)
    colors = if iscontour(series)
        levels = gr_contour_levels(series, clims)
        zrange = if isfilledcontour(series)
            ignorenan_extrema(levels)  # GR.contourf uses a color range according to supplied levels
        else
            clims  # GR.contour uses a color range according to data range
        end
        1_000 .+ 255 .* (levels .- zrange[1]) ./ (zrange[2] - zrange[1])
    else
        1_000:1_255
    end
    round.(Int, colors)
end

function _cbar_unique(values, propname)
    out = last(values)
    if any(x != out for x in values)
        @warn "Multiple series with different $propname share a colorbar. " *
              "Colorbar may not reflect all series correctly."
    end
    out
end

const gr_colorbar_tick_size = Ref(0.005)

# add the colorbar
function gr_draw_colorbar(cbar::GRColorbar, sp::Subplot, clims, vp)
    GR.savestate()
    x_min, x_max = gr_x_axislims(sp)
    z_min, z_max = clims
    gr_set_viewport_cmap(sp, vp)
    GR.setscale(0)
    GR.setwindow(x_min, x_max, z_min, z_max)
    if !isempty(cbar.gradients)
        series = cbar.gradients
        gr_set_gradient(_cbar_unique(get_colorgradient.(series), "color"))
        gr_set_transparency(_cbar_unique(get_fillalpha.(series), "fill alpha"))
        GR.cellarray(x_min, x_max, z_max, z_min, 1, 256, 1_000:1_255)
    end

    if !isempty(cbar.fills)
        series = cbar.fills
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        gr_set_gradient(_cbar_unique(get_colorgradient.(series), "color"))
        gr_set_transparency(_cbar_unique(get_fillalpha.(series), "fill alpha"))
        levels = _cbar_unique(contour_levels.(series, Ref(clims)), "levels")
        # GR implicitly uses the maximal z value as the highest level
        if last(levels) < clims[2]
            @warn "GR: highest contour level less than maximal z value is not supported."
            # replace levels, rather than assign to last(levels), to ensure type
            # promotion in case levels is an integer array
            pop!(levels)
            push!(levels, clims[2])
        end
        colors = gr_colorbar_colors(last(series), clims)
        for (from, to, color) in zip(levels[1:(end - 1)], levels[2:end], colors)
            GR.setfillcolorind(color)
            GR.fillrect(x_min, x_max, from, to)
        end
    end

    if !isempty(cbar.lines)
        series = cbar.lines
        gr_set_gradient(_cbar_unique(get_colorgradient.(series), "color"))
        gr_set_line(
            _cbar_unique(get_linewidth.(series), "line width"),
            _cbar_unique(get_linestyle.(series), "line style"),
            _cbar_unique(get_linecolor.(series, Ref(clims)), "line color"),
            sp,
        )
        gr_set_transparency(_cbar_unique(get_linealpha.(series), "line alpha"))
        levels = _cbar_unique(contour_levels.(series, Ref(clims)), "levels")
        colors = gr_colorbar_colors(last(series), clims)
        for (line, color) in zip(levels, colors)
            GR.setlinecolorind(color)
            GR.polyline([x_min, x_max], [line, line])
        end
    end

    z_tick = 0.5GR.tick(z_min, z_max)
    gr_set_line(1, :solid, plot_color(:black), sp)
    sp[:colorbar_scale] === :log10 && GR.setscale(GR.OPTION_Y_LOG)
    # gr.axes(x_tick, y_tick, x_org, y_org, major_x, major_y, tick_size)
    GR.axes(0, z_tick, x_max, z_min, 0, 1, gr_colorbar_tick_size[])

    title = if sp[:colorbar_title] isa PlotText
        sp[:colorbar_title]
    else
        text(sp[:colorbar_title], colorbartitlefont(sp))
    end
    gr_set_font(title.font, sp; halign = :center, valign = :top)
    GR.setcharup(-1, 0)
    gr_text(xmax(vp) + 0.1, ycenter(vp), title.str)

    GR.restorestate()
end

position(symb) =
    if symb === :top || symb === :right
        0.95
    elseif symb === :left || symb === :bottom
        0.05
    else
        0.5
    end

alignment(symb) =
    if symb === :top || symb === :right
        :right
    elseif symb === :left || symb === :bottom
        :left
    else
        :center
    end

# --------------------------------------------------------------------------------------

function gr_set_gradient(c)
    grad = _as_gradient(c)
    for (i, z) in enumerate(range(0, 1; length = 256))
        c = grad[z]
        GR.setcolorrep(999 + i, red(c), green(c), blue(c))
    end
    grad
end

gr_set_gradient(series::Series) =
    (color = get_colorgradient(series)) !== nothing && gr_set_gradient(color)

# this is our new display func... set up the viewport_canvas, compute bounding boxes, and display each subplot
function gr_display(plt::Plot, dpi_factor = 1)
    GR.clearws()

    # collect some monitor/display sizes in meters and pixels
    dsp_width_meters, dsp_height_meters, dsp_width_px, dsp_height_px = GR.inqdspsize()
    dsp_width_ratio = dsp_width_meters / dsp_width_px
    dsp_height_ratio = dsp_height_meters / dsp_height_px

    # compute the viewport_canvas, normalized to the larger dimension
    vp_canvas = GRViewport(0.0, 1.0, 0.0, 1.0)
    w, h = get_size(plt)
    if w > h
        ratio = float(h) / w
        msize = dsp_width_ratio * w * dpi_factor
        GR.setwsviewport(0, msize, 0, msize * ratio)
        GR.setwswindow(0, 1, 0, ratio)
        vp_canvas.ymin[] *= ratio
        vp_canvas.ymax[] *= ratio
    else
        ratio = float(w) / h
        msize = dsp_height_ratio * h * dpi_factor
        GR.setwsviewport(0, msize * ratio, 0, msize)
        GR.setwswindow(0, ratio, 0, 1)
        vp_canvas.xmin[] *= ratio
        vp_canvas.xmax[] *= ratio
    end

    # fill in the viewport_canvas background
    gr_fill_viewport(vp_canvas, plt[:background_color_outside])

    # subplots:
    for sp in plt.subplots
        gr_display(sp, w * px, h * px, vp_canvas)
    end

    GR.updatews()
end

gr_set_tickfont(sp, ax::Axis; kw...) = gr_set_font(
    tickfont(ax),
    sp;
    rotation = ax[:rotation],
    color = ax[:tickfontcolor],
    kw...,
)

function gr_set_tickfont(sp, letter::Symbol; kw...)
    axis = sp[get_attr_symbol(letter, :axis)]
    gr_set_font(
        tickfont(axis),
        sp;
        rotation = axis[:rotation],
        color = axis[:tickfontcolor],
        kw...,
    )
end

# size of the text with no rotation
function gr_text_size(str)
    GR.savestate()
    GR.selntran(0)
    GR.setcharup(0, 1)
    xs, ys = gr_inqtext(0, 0, string(str))
    l, r = extrema(xs)
    b, t = extrema(ys)
    w = r - l
    h = t - b
    GR.restorestate()
    w, h
end

# size of the text with rotation applied
function gr_text_size(str, rot)
    GR.savestate()
    GR.selntran(0)
    GR.setcharup(0, 1)
    xs, ys = gr_inqtext(0, 0, string(str))
    l, r = extrema(xs)
    b, t = extrema(ys)
    w = text_box_width(r - l, t - b, rot)
    h = text_box_height(r - l, t - b, rot)
    GR.restorestate()
    w, h
end

text_box_width(w, h, rot) = abs(cosd(rot)) * w + abs(cosd(rot + 90)) * h
text_box_height(w, h, rot) = abs(sind(rot)) * w + abs(sind(rot + 90)) * h

function gr_get_3d_axis_angle(cvs, nt, ft, letter)
    length(cvs) < 2 && return 0
    tickpoints = map(cv -> gr_w3tondc(sort_3d_axes(cv, nt, ft, letter)...), cvs)

    dx = tickpoints[2][1] - tickpoints[1][1]
    dy = tickpoints[2][2] - tickpoints[1][2]
    atand(dy, dx)
end

function gr_get_ticks_size(ticks, rot)
    w, h = 0.0, 0.0
    for (cv, dv) in zip(ticks...)
        wi, hi = gr_text_size(dv, rot)
        w = NaNMath.max(w, wi)
        h = NaNMath.max(h, hi)
    end
    w, h
end

function labelfunc(scale::Symbol, backend::GRBackend)
    texfunc = labelfunc_tex(scale)
    # replace dash with \minus (U+2212)
    label -> replace(texfunc(label), "-" => "−")
end

function gr_axis_height(sp, axis)
    GR.savestate()
    ticks = get_ticks(sp, axis, update = false)
    gr_set_font(tickfont(axis), sp)
    h = (
        ticks in (nothing, false, :none) ? 0 :
        last(gr_get_ticks_size(ticks, axis[:rotation]))
    )
    if axis[:guide] != ""
        gr_set_font(guidefont(axis), sp)
        h += last(gr_text_size(axis[:guide]))
    end
    GR.restorestate()
    h
end

function gr_axis_width(sp, axis)
    GR.savestate()
    ticks = get_ticks(sp, axis, update = false)
    gr_set_font(tickfont(axis), sp)
    w = (
        ticks in (nothing, false, :none) ? 0 :
        first(gr_get_ticks_size(ticks, axis[:rotation]))
    )
    if axis[:guide] != ""
        gr_set_font(guidefont(axis), sp)
        w += last(gr_text_size(axis[:guide]))
    end
    GR.restorestate()
    w
end

function _update_min_padding!(sp::Subplot{GRBackend})
    dpi = sp.plt[:thickness_scaling]
    width, height = sp_size = get_size(sp)

    # Add margin given by the user
    padding = (
        left = Ref(2mm + sp[:left_margin]),
        top = Ref(2mm + sp[:top_margin]),
        right = Ref(2mm + sp[:right_margin]),
        bottom = Ref(2mm + sp[:bottom_margin]),
    )

    # Add margin for title
    if (title = sp[:title]) != ""
        gr_set_font(titlefont(sp), sp)
        l = last(gr_text_size(title))
        padding.top[] += 1mm + height * l * px
    end

    xaxis, yaxis, zaxis = axes = sp[:xaxis], sp[:yaxis], sp[:zaxis]
    xticks, yticks, zticks = get_ticks.(Ref(sp), axes)

    if gr_is3d(sp)
        # Add margin for x and y ticks
        m = 0mm
        for (ax, tc) in ((xaxis, xticks), (yaxis, yticks))
            isempty(first(tc)) && continue
            rot = ax[:rotation]
            gr_set_tickfont(
                sp,
                ax;
                halign = (:left, :hcenter, :right)[sign(rot) + 2],
                valign = (ax[:mirror] ? :bottom : :top),
            )
            l = 0.01 + last(gr_get_ticks_size(tc, rot))
            m = max(m, 1mm + height * l * px)
        end
        if m > 0mm
            (xaxis[:mirror] || yaxis[:mirror]) && (padding.top[] += m)
            (!xaxis[:mirror] || !yaxis[:mirror]) && (padding.bottom[] += m)
        end

        if !isempty(first(zticks))
            rot = zaxis[:rotation]
            gr_set_tickfont(
                sp,
                zaxis;
                halign = (zaxis[:mirror] ? :left : :right),
                valign = (:top, :vcenter, :bottom)[sign(rot) + 2],
            )
            l = 0.01 + first(gr_get_ticks_size(zticks, rot))
            padding[zaxis[:mirror] ? :right : :left][] += 1mm + width * l * px
        end

        # Add margin for x or y label
        m = 0mm
        for ax in (xaxis, yaxis)
            (guide = ax[:guide] == "") && continue
            gr_set_font(guidefont(ax), sp)
            l = last(gr_text_size(guide))
            m = max(m, 1mm + height * l * px)
        end
        if m > 0mm
            # NOTE: `xaxis` arbitrary here ?
            padding[mirrored(xaxis, :top) ? :top : :bottom][] += m
        end
        # Add margin for z label
        if (guide = zaxis[:guide]) != ""
            gr_set_font(guidefont(zaxis), sp)
            l = last(gr_text_size(guide))
            padding[mirrored(zaxis, :right) ? :right : :left][] += 1mm + height * l * px  # NOTE:  why `height` here ?
        end
    else
        # Add margin for x/y ticks & labels
        for (ax, tc, (a, b)) in
            ((xaxis, xticks, (:top, :bottom)), (yaxis, yticks, (:right, :left)))
            if !isempty(first(tc))
                isy = ax[:letter] === :y
                gr_set_tickfont(sp, ax)
                ts = gr_get_ticks_size(tc, ax[:rotation])
                l = 0.01 + (isy ? first(ts) : last(ts))
                padding[ax[:mirror] ? a : b][] += 1mm + sp_size[isy ? 1 : 2] * l * px
            end
            if (guide = ax[:guide]) != ""
                gr_set_font(guidefont(ax), sp)
                l = last(gr_text_size(guide))
                padding[mirrored(ax, a) ? a : b][] += 1mm + height * l * px  # NOTE: using `height` is arbitrary
            end
        end
    end
    sp[:colorbar_title] == "" || (padding.right[] += 4mm)
    sp.minpad = (
        dpi * padding.left[],
        dpi * padding.top[],
        dpi * padding.right[],
        dpi * padding.bottom[],
    )
end

remap(x, lo, hi) = (x - lo) / (hi - lo)
get_z_normalized(z, clims...) = isnan(z) ? 256 / 255 : remap(clamp(z, clims...), clims...)

function gr_clims(sp, args...)
    sp[:clims] === :auto || return get_clims(sp)
    lo, hi = get_clims(sp, args...)
    if lo == hi
        if lo == 0
            hi = one(hi)
        elseif lo < 0
            hi = zero(hi)
        else
            lo = zero(lo)
        end
    end
    lo, hi
end

function gr_display(sp::Subplot{GRBackend}, w, h, vp_canvas)
    _update_min_padding!(sp)

    # the viewports for this subplot and the whole plot
    vp_sp = gr_viewport_from_bbox(sp, bbox(sp), w, h, vp_canvas)
    vp_plt = gr_viewport_from_bbox(sp, plotarea(sp), w, h, vp_canvas)

    # update plot viewport
    leg = gr_get_legend_geometry(vp_plt, sp)
    gr_update_viewport_legend!(vp_plt, sp, leg)
    gr_update_viewport_ratio!(vp_plt, sp)

    # fill in the plot area background
    gr_fill_plotarea(sp, vp_plt)

    # set our plot area view
    GR.setviewport(xyminmax(vp_plt)...)

    # set the scale flags and window
    gr_set_window(sp, vp_plt)

    # draw the axes
    gr_draw_axes(sp, vp_plt)
    gr_add_title(sp, vp_plt, vp_sp)

    # this needs to be here to point the colormap to the right indices
    GR.setcolormap(1_000 + GR.COLORMAP_COOLWARM)

    # init the colorbar
    cbar = GRColorbar()

    for series in series_list(sp)
        gr_add_series(sp, series)
        gr_update_colorbar!(cbar, series)
    end

    # draw the colorbar
    hascolorbar(sp) && gr_draw_colorbar(cbar, sp, gr_clims(sp), vp_plt)

    # add the legend
    gr_add_legend(sp, leg, vp_plt)

    # add annotations
    for ann in sp[:annotations]
        x, y, val = locate_annotation(sp, ann...)
        x, y = gr_is3d(sp) ? gr_w3tondc(x, y, z) : GR.wctondc(x, y)
        gr_set_font(val.font, sp)
        gr_text(x, y, val.str)
    end
end

## Legend

const gr_legend_marker_to_line_factor = Ref(4.0)

function gr_add_legend(sp, leg, viewport_area)
    sp[:legend_position] ∈ (:none, :inline) && return
    GR.savestate()
    GR.selntran(0)
    GR.setscale(0)
    if leg.w > 0
        xpos, ypos = gr_legend_pos(sp, leg, viewport_area)
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        gr_set_fillcolor(sp[:legend_background_color])
        GR.fillrect(
            xpos - leg.leftw,
            xpos + leg.textw + leg.rightw,
            ypos + leg.dy,
            ypos - leg.h,
        ) # Allocating white space for actual legend width here
        gr_set_line(1, :solid, sp[:legend_foreground_color], sp)
        GR.drawrect(
            xpos - leg.leftw,
            xpos + leg.textw + leg.rightw,
            ypos + leg.dy,
            ypos - leg.h,
        ) # Drawing actual legend width here
        if sp[:legend_title] !== nothing
            gr_set_font(legendtitlefont(sp), sp; halign = :center, valign = :center)
            gr_text(xpos - 0.03 + 0.5leg.w, ypos, string(sp[:legend_title]))
            ypos -= leg.dy
        end
        gr_set_font(legendfont(sp), sp; halign = :left, valign = :center)
        for series in series_list(sp)
            should_add_to_legend(series) || continue
            st = series[:seriestype]
            clims = gr_clims(sp, series)
            lc = get_linecolor(series, clims)
            lfps = sp[:legend_font_pointsize]
            gr_set_line(lfps / 8, get_linestyle(series), lc, sp)

            lft, rgt, bot, top =
                0.5leg.width_factor, 3.5leg.width_factor, 0.4leg.dy, 0.4leg.dy

            if (
                (st === :shape || series[:fillrange] !== nothing) &&
                series[:ribbon] === nothing
            )
                (fc = get_fillcolor(series, clims)) |> gr_set_fill
                gr_set_fillstyle(get_fillstyle(series, 0))
                l, r = xpos - lft, xpos - rgt
                b, t = ypos - bot, ypos + top
                x = [l, r, r, l, l]
                y = [b, b, t, t, b]
                gr_set_transparency(fc, get_fillalpha(series))
                gr_polyline(x, y, GR.fillarea)
                lc = get_linecolor(series, clims)
                gr_set_transparency(lc, get_linealpha(series))
                gr_set_line(get_linewidth(series), get_linestyle(series), lc, sp)
                st === :shape && gr_polyline(x, y)
            end

            maxmarkersize = Inf
            if st in (:path, :straightline, :path3d)
                gr_set_transparency(lc, get_linealpha(series))
                # This is to prevent that linestyle is obscured by large markers. 
                # We are trying to get markers to not be larger than half the line length. 
                # 1 / leg.dy translates width_factor to line length units (important in the context of size kwarg)
                # gr_legend_marker_to_line_factor is an empirical constant to translate between line length unit and marker size unit
                maxmarkersize = gr_legend_marker_to_line_factor[] * 0.5(rgt - lft) / leg.dy
                if series[:fillrange] === nothing || series[:ribbon] !== nothing
                    GR.polyline([xpos - rgt, xpos - lft], [ypos, ypos])
                else
                    GR.polyline([xpos - rgt, xpos - lft], [ypos + bot, ypos + top])
                end
            end

            if (msh = series[:markershape]) !== :none
                msz = first(series[:markersize])
                msw = first(series[:markerstrokewidth])
                gr_draw_marker(
                    series,
                    xpos - 2leg.width_factor,
                    ypos,
                    nothing,
                    clims,
                    1,
                    min(maxmarkersize, msz > 0 ? 0.8lfps : 0),
                    min(maxmarkersize, 0.8lfps * msw / (msz > 0 ? msz : 8)),
                    Plots._cycle(msh, 1),
                )
            end

            gr_set_textcolor(plot_color(sp[:legend_font_color]))
            gr_text(xpos, ypos, string(series[:label]))
            ypos -= leg.dy
        end
    end
    GR.selntran(1)
    GR.restorestate()
end

mirrored(ax::Axis, sym::Symbol) =
    ax[:guide_position] === sym || (ax[:guide_position] === :auto && ax[:mirror])

function gr_legend_pos(sp::Subplot, leg, vp)
    xaxis, yaxis = sp[:xaxis], sp[:yaxis]
    xmirror = mirrored(xaxis, :top)
    ymirror = mirrored(yaxis, :right)
    if (s = sp[:legend_position]) isa Real
        return gr_legend_pos(s, leg, vp)
    elseif s isa Tuple{<:Real,Symbol}
        s[2] === :outer || return gr_legend_pos(s[1], leg, vp)
        axisclearance = [
            !ymirror * gr_axis_width(sp, yaxis),
            ymirror * gr_axis_width(sp, yaxis),
            !xmirror * gr_axis_height(sp, xaxis),
            xmirror * gr_axis_height(sp, xaxis),
        ]
        return gr_legend_pos(s[1], leg, vp; axisclearance)
    elseif !(s isa Symbol)
        return gr_legend_pos(s, vp)
    end
    (str = string(s)) == "best" && (str = "topright")
    xpos = if occursin("left", str)
        if occursin("outer", str)
            -!ymirror * gr_axis_width(sp, yaxis) - 2leg.xoffset - leg.rightw - leg.textw
        else
            leg.leftw + leg.xoffset
        end + xmin(vp)
    elseif occursin("right", str)
        if occursin("outer", str)  # per https://github.com/jheinen/GR.jl/blob/master/src/jlgr.jl#L525
            leg.xoffset + leg.leftw + ymirror * gr_axis_width(sp, yaxis)
        else
            -leg.rightw - leg.textw - leg.xoffset
        end + xmax(vp)
    else
        xposition(vp, 0) + leg.leftw - leg.rightw - leg.textw - 2leg.xoffset
    end
    ypos = if occursin("bottom", str)
        if s === :outerbottom
            -leg.yoffset - leg.dy - !xmirror * gr_axis_height(sp, xaxis)
        else
            leg.yoffset + leg.h
        end + ymin(vp)
    elseif occursin("top", str)
        if s === :outertop
            leg.yoffset + leg.h + xmirror * gr_axis_height(sp, xaxis)
        else
            -leg.yoffset - leg.dy
        end + ymax(vp)
    else
        # Adding min y to shift legend pos to correct graph (#2377)
        0.5(height(vp) + leg.h) + xmin(vp)
    end
    xpos, ypos
end

function gr_get_legend_geometry(vp, sp)
    legendn = 0
    legendw = dy = 0.0
    if sp[:legend_position] !== :none
        GR.savestate()
        GR.selntran(0)
        GR.setcharup(0, 1)
        GR.setscale(0)
        if sp[:legend_title] !== nothing
            gr_set_font(legendtitlefont(sp), sp)
            tbx, tby = gr_inqtext(0, 0, string(sp[:legend_title]))
            l, r = extrema(tbx)
            b, t = extrema(tby)
            dy = t - b
            legendw = r - l
            legendn += 1
        end
        gr_set_font(legendfont(sp), sp)
        for series in series_list(sp)
            should_add_to_legend(series) || continue
            tbx, tby = gr_inqtext(0, 0, string(series[:label]))
            l, r = extrema(tbx)
            b, t = extrema(tby)
            dy = max(dy, t - b)
            legendw = max(legendw, r - l) # Holds text width right now
            legendn += 1
        end

        GR.setscale(GR.OPTION_X_LOG)
        GR.selntran(1)
        GR.restorestate()
    end

    legend_width_factor = width(vp) / 45 # Determines the width of legend box
    legend_textw = legendw
    legend_rightw = legend_width_factor
    legend_leftw = 4legend_width_factor
    total_legendw = legend_textw + legend_leftw + legend_rightw

    x_legend_offset = width(vp) / 30
    y_legend_offset = height(vp) / 30

    dy *= get(sp[:extra_kwargs], :legend_hfactor, 1)
    legendh = dy * legendn

    (
        w = legendw,
        h = legendh,
        dy = dy,
        leftw = legend_leftw,
        textw = legend_textw,
        rightw = legend_rightw,
        xoffset = x_legend_offset,
        yoffset = y_legend_offset,
        width_factor = legend_width_factor,
    )
end

## Viewport, window and scale

function gr_update_viewport_legend!(vp, sp, leg)
    xaxis, yaxis = sp[:xaxis], sp[:yaxis]
    xmirror = mirrored(xaxis, :top)
    ymirror = mirrored(yaxis, :right)
    if (s = sp[:legend_position]) isa Tuple{<:Real,Symbol}
        if s[2] === :outer
            x, y = gr_legend_pos(sp, leg, vp) # Dry run, to figure out
            if x < xmin(vp)
                vp.xmin[] +=
                    leg.leftw +
                    leg.textw +
                    leg.rightw +
                    leg.xoffset +
                    !ymirror * gr_axis_width(sp, yaxis)
            elseif x > xmax(vp)
                vp.xmax[] -= leg.leftw + leg.textw + leg.rightw + leg.xoffset
            end
            if y < ymin(vp)
                vp.ymin[] +=
                    leg.h + leg.dy + leg.yoffset + !xmirror * gr_axis_height(sp, xaxis)
            elseif y > ymax(vp)
                vp.ymax[] -= leg.h + leg.dy + leg.yoffset
            end
        end
    end
    leg_str = string(s)
    if occursin("outer", leg_str)
        if occursin("right", leg_str)
            vp.xmax[] -= leg.leftw + leg.textw + leg.rightw + leg.xoffset
        elseif occursin("left", leg_str)
            vp.xmin[] +=
                leg.leftw +
                leg.textw +
                leg.rightw +
                leg.xoffset +
                !ymirror * gr_axis_width(sp, yaxis)
        elseif occursin("top", leg_str)
            vp.ymax[] -= leg.h + leg.dy + leg.yoffset
        elseif occursin("bottom", leg_str)
            vp.ymin[] += leg.h + leg.dy + leg.yoffset + !xmirror * gr_axis_height(sp, xaxis)
        end
    end
    if s === :inline
        if yaxis[:mirror]
            vp.xmin[] += leg.w
        else
            vp.xmax[] -= leg.w
        end
    end
    nothing
end

function gr_update_viewport_ratio!(vp, sp)
    if (ratio = get_aspect_ratio(sp)) !== :none
        ratio === :equal && (ratio = 1)
        x_min, x_max, y_min, y_max = gr_xy_axislims(sp)
        viewport_ratio = width(vp) / height(vp)
        window_ratio = (x_max - x_min) / (y_max - y_min) / ratio
        if window_ratio < viewport_ratio
            viewport_center = xcenter(vp)
            viewport_size = width(vp) * window_ratio / viewport_ratio
            vp.xmin[] = viewport_center - 0.5viewport_size
            vp.xmax[] = viewport_center + 0.5viewport_size
        elseif window_ratio > viewport_ratio
            viewport_center = ycenter(vp)
            viewport_size = height(vp) * viewport_ratio / window_ratio
            vp.ymin[] = viewport_center - 0.5viewport_size
            vp.ymax[] = viewport_center + 0.5viewport_size
        end
    end
end

function gr_set_window(sp, vp)
    if ispolar(sp)
        gr_set_viewport_polar(vp)
    else
        x_min, x_max, y_min, y_max = gr_xy_axislims(sp)
        zok = if (needs_3d = needs_any_3d_axes(sp))
            z_min, z_max = gr_z_axislims(sp)
            z_max > z_min
        else
            true
        end

        if x_max > x_min && y_max > y_min && zok
            scaleop = 0
            sp[:xaxis][:scale] === :log10 && (scaleop |= GR.OPTION_X_LOG)
            sp[:yaxis][:scale] === :log10 && (scaleop |= GR.OPTION_Y_LOG)
            (needs_3d && sp[:zaxis][:scale] === :log10) && (scaleop |= GR.OPTION_Z_LOG)
            sp[:xaxis][:flip] && (scaleop |= GR.OPTION_FLIP_X)
            sp[:yaxis][:flip] && (scaleop |= GR.OPTION_FLIP_Y)
            (needs_3d && sp[:zaxis][:flip]) && (scaleop |= GR.OPTION_FLIP_Z)
            # NOTE: setwindow sets the "data coordinate" limits of the current "viewport"
            GR.setwindow(x_min, x_max, y_min, y_max)
            GR.setscale(scaleop)
        end
    end
end

## Axes

function gr_draw_axes(sp, vp)
    GR.setlinewidth(sp.plt[:thickness_scaling])

    if gr_is3d(sp)
        # set space
        x_min, x_max, y_min, y_max = gr_xy_axislims(sp)
        z_min, z_max = gr_z_axislims(sp)

        azimuth, elevation = sp[:camera]

        GR.setwindow3d(x_min, x_max, y_min, y_max, z_min, z_max)
        fov = isortho(sp) || isautop(sp) ? NaN : 30
        cam = isortho(sp) || isautop(sp) ? 0 : NaN
        GR.setspace3d(-90 + azimuth, 90 - elevation, fov, cam)
        gr_set_projectiontype(sp)

        # fill the plot area
        gr_set_fill(plot_color(sp[:background_color_inside]))
        area_x = [x_min, x_min, x_min, x_max, x_max, x_max, x_min]
        area_y = [y_min, y_min, y_max, y_max, y_max, y_min, y_min]
        area_z = [z_min, z_max, z_max, z_max, z_min, z_min, z_min]
        x_bg, y_bg = RecipesPipeline.unzip(GR.wc3towc.(area_x, area_y, area_z))
        GR.fillarea(x_bg, y_bg)

        foreach(letter -> gr_draw_axis_3d(sp, letter, vp), (:x, :y, :z))
    elseif ispolar(sp)
        r = gr_set_viewport_polar(vp)
        # rmin, rmax = GR.adjustrange(ignorenan_minimum(r), ignorenan_maximum(r))
        rmin, rmax = axis_limits(sp, :y)
        gr_polaraxes(rmin, rmax, sp)
    elseif sp[:framestyle] !== :none
        foreach(letter -> gr_draw_axis(sp, letter, vp), (:x, :y))
    end
end

function gr_draw_axis(sp, letter, vp)
    ax = axis_drawing_info(sp, letter)
    axis = sp[get_attr_symbol(letter, :axis)]

    # draw segments
    gr_draw_grid(sp, axis, ax.grid_segments)
    gr_draw_minorgrid(sp, axis, ax.minorgrid_segments)
    gr_draw_spine(sp, axis, ax.segments)
    gr_draw_border(sp, axis, ax.border_segments)
    gr_draw_ticks(sp, axis, ax.tick_segments)

    # labels
    gr_label_ticks(sp, letter, ax.ticks)
    gr_label_axis(sp, letter, vp)
end

function gr_draw_axis_3d(sp, letter, vp)
    ax = axis_drawing_info_3d(sp, letter)
    axis = sp[get_attr_symbol(letter, :axis)]

    # draw segments
    gr_draw_grid(sp, axis, ax.grid_segments, gr_polyline3d)
    gr_draw_minorgrid(sp, axis, ax.minorgrid_segments, gr_polyline3d)
    gr_draw_spine(sp, axis, ax.segments, gr_polyline3d)
    gr_draw_border(sp, axis, ax.border_segments, gr_polyline3d)
    gr_draw_ticks(sp, axis, ax.tick_segments, gr_polyline3d)

    # labels
    GR.setscale(0)
    gr_label_ticks_3d(sp, letter, ax.ticks)
    gr_label_axis_3d(sp, letter)
    gr_set_window(sp, vp)
end

gr_draw_grid(sp, axis, segments, func = gr_polyline) =
    if axis[:grid]
        gr_set_line(
            axis[:gridlinewidth],
            axis[:gridstyle],
            axis[:foreground_color_grid],
            sp,
        )
        gr_set_transparency(axis[:foreground_color_grid], axis[:gridalpha])
        func(coords(segments)...)
    end

gr_draw_minorgrid(sp, axis, segments, func = gr_polyline) =
    if axis[:minorgrid]
        gr_set_line(
            axis[:minorgridlinewidth],
            axis[:minorgridstyle],
            axis[:foreground_color_minor_grid],
            sp,
        )
        gr_set_transparency(axis[:foreground_color_minor_grid], axis[:minorgridalpha])
        func(coords(segments)...)
    end

gr_draw_spine(sp, axis, segments, func = gr_polyline) =
    if axis[:showaxis]
        gr_set_line(1, :solid, axis[:foreground_color_border], sp)
        gr_set_transparency(1.0)
        GR.setclip(0)
        func(coords(segments)...)
        GR.setclip(1)
    end

gr_draw_border(sp, axis, segments, func = gr_polyline) =
    if sp[:framestyle] in (:box, :semi)
        intensity = sp[:framestyle] === :semi ? 0.5 : 1
        GR.setclip(0)
        gr_set_line(intensity, :solid, axis[:foreground_color_border], sp)
        gr_set_transparency(axis[:foreground_color_border], intensity)
        func(coords(segments)...)
        GR.setclip(1)
    end

gr_draw_ticks(sp, axis, segments, func = gr_polyline) =
    if axis[:showaxis]
        if sp[:framestyle] in (:zerolines, :grid)
            gr_set_line(1, :solid, axis[:foreground_color_grid], sp)
            gr_set_transparency(
                axis[:foreground_color_grid],
                axis[:tick_direction] === :out ? axis[:gridalpha] : 0,
            )
        else
            gr_set_line(1, :solid, axis[:foreground_color_axis], sp)
        end
        GR.setclip(0)
        func(coords(segments)...)
        GR.setclip(1)
    end

function gr_label_ticks(sp, letter, ticks)
    letters = axes_letters(sp, letter)
    ax, oax = map(l -> sp[get_attr_symbol(l, :axis)], letters)
    _, (oamin, oamax) = map(l -> axis_limits(sp, l), letters)

    gr_set_tickfont(sp, letter)
    out_factor = ifelse(ax[:tick_direction] === :out, 1.5, 1)

    isy = letter === :y
    x_offset = isy ? -0.015out_factor : 0
    y_offset = isy ? 0 : -0.008out_factor

    rot = ax[:rotation] % 360
    ov = sp[:framestyle] === :origin ? 0 : xor(oax[:flip], ax[:mirror]) ? oamax : oamin
    sgn = ax[:mirror] ? -1 : 1
    sgn2 = iseven(Int(floor(rot / 90))) ? -1 : 1
    sgn3 = if isy
        -360 < rot < -180 || 0 < rot < 180 ? 1 : -1
    else
        rot < -270 || -90 < rot < 90 || rot > 270 ? 1 : -1
    end
    for (cv, dv) in zip(ticks...)
        x, y = GR.wctondc(reverse_if((cv, ov), isy)...)
        sz_rot, sz = gr_text_size(dv, rot), gr_text_size(dv)
        x_off, y_off = x_offset, y_offset
        if isy
            x_off += -first(sz_rot) / 2
            if rot % 90 != 0
                y_off += 0.5(sgn2 * last(sz_rot) + sgn3 * last(sz) * cosd(rot))
            end
        else
            if rot % 90 != 0
                x_off += 0.5(sgn2 * first(sz_rot) + sgn3 * last(sz) * sind(rot))
            end
            y_off += -last(sz_rot) / 2
        end
        gr_text(x + sgn * x_off, y + sgn * y_off, dv)
    end
end

gr_label_ticks(sp, letter, ticks::Nothing) = nothing

function gr_label_ticks_3d(sp, letter, ticks)
    letters = axes_letters(sp, letter)
    _, (namin, namax), (famin, famax) = map(l -> axis_limits(sp, l), letters)
    ax = sp[get_attr_symbol(letter, :axis)]

    isy, isz = letter .=== (:y, :z)
    n0, n1 = isy ? (namax, namin) : (namin, namax)

    gr_set_tickfont(sp, letter)
    nt = sp[:framestyle] === :origin ? 0 : ax[:mirror] ? n1 : n0
    ft = sp[:framestyle] === :origin ? 0 : ax[:mirror] ? famax : famin

    rot = mod(ax[:rotation], 360)
    sgn = ax[:mirror] ? -1 : 1

    cvs, dvs = ticks

    axisθ = isz ? 270 : mod(gr_get_3d_axis_angle(cvs, nt, ft, letter), 360)  # issue: doesn't work with 1 tick
    axisϕ = mod(axisθ - 90, 360)

    out_factor = ifelse(ax[:tick_direction] === :out, 1.5, 1)
    axis_offset = 0.012out_factor
    x_offset = axis_offset * cosd(axisϕ)
    y_offset = axis_offset * sind(axisϕ)

    sgn2a = sgn2b = sgn3 = 0
    if axisθ != 0 || rot % 90 != 0
        sgn2a =
            (axisθ != 90) && (axisθ == 0 && (rot < 90 || 180 ≤ rot < 270)) ||
            (axisθ == 270) ||
            (axisθ < 90 && (axisθ < rot < 90 || axisθ + 180 < rot < 270)) ||
            (axisθ > 270 && (rot < 90 || axisθ - 180 < rot < 270 || rot > axisθ)) ? -1 : 1
    end

    if (axisθ - 90) % 180 != 0 || (rot - 90) % 180 != 0
        sgn2b =
            axisθ == 0 ||
            (axisθ == 90 && (90 ≤ rot < 180 || 270 ≤ rot < 360)) ||
            (axisθ == 270 && (rot < 90 || 180 ≤ rot < 270)) ||
            (axisθ < 90 && (axisθ < rot < 180 || axisθ + 180 < rot)) ||
            (axisθ > 270 && (rot < axisθ - 180 || 180 ≤ rot < axisθ)) ? -1 : 1
    end

    if !(axisθ == 0 && rot % 180 == 0) && (rot - 90) % 180 != 0
        sgn3 =
            (axisθ == 0 && 90 < rot < 270) ||
            (axisθ == 90 && rot < 180) ||
            (axisθ == 270 && rot > 180) ||
            (axisθ < 90 && (rot < axisθ || 90 ≤ rot < 180 || axisθ + 180 < rot < 270)) ||
            (axisθ > 270 && (90 ≤ rot < axisθ - 180 || 180 ≤ rot < 270 || rot > axisθ)) ?
            -1 : 1
    end

    GR.setwindow(-1, 1, -1, 1)
    for (cv, dv) in zip((ax[:flip] ? reverse(cvs) : cvs, dvs)...)
        xi, yi = gr_w3tondc(sort_3d_axes(cv, nt, ft, letter)...)
        sz_rot, sz = gr_text_size(dv, rot), gr_text_size(dv)
        x_off = x_offset + 0.5(sgn2a * first(sz_rot) + sgn3 * last(sz) * sind(rot))
        y_off = y_offset + 0.5(sgn2b * last(sz_rot) + sgn3 * last(sz) * cosd(rot))
        gr_text(xi + sgn * x_off, yi + sgn * y_off, dv)
    end
end

gr_label_axis(sp, letter, vp) =
    if (axis = sp[get_attr_symbol(letter, :axis)])[:guide] != ""
        mirror = axis[:mirror]
        GR.savestate()
        guide_position = axis[:guide_position]
        rotation = float(axis[:guidefontrotation])  # github.com/JuliaPlots/Plots.jl/issues/3089
        if letter === :x
            # default rotation = 0. should yield GR.setcharup(0, 1) i.e. 90°
            xpos = xposition(vp, position(axis[:guidefonthalign]))
            halign = alignment(axis[:guidefonthalign])
            ypos, valign =
                if guide_position === :top || (guide_position === :auto && mirror)
                    ymax(vp) + 0.015 + (mirror ? gr_axis_height(sp, axis) : 0.015), :top
                else
                    ymin(vp) - 0.015 - (mirror ? 0.015 : gr_axis_height(sp, axis)), :bottom
                end
        else
            rotation += 90  # default rotation = 0. should yield GR.setcharup(-1, 0) i.e. 180°
            ypos = yposition(vp, position(axis[:guidefontvalign]))
            halign = alignment(axis[:guidefontvalign])
            xpos, valign =
                if guide_position === :right || (guide_position === :auto && mirror)
                    xmax(vp) + 0.03 + mirror * gr_axis_width(sp, axis), :bottom
                else
                    xmin(vp) - 0.03 - !mirror * gr_axis_width(sp, axis), :top
                end
        end
        gr_set_font(guidefont(axis), sp; rotation, halign, valign)
        gr_text(xpos, ypos, axis[:guide])
        GR.restorestate()
    end

gr_label_axis_3d(sp, letter) =
    if (ax = sp[get_attr_symbol(letter, :axis)])[:guide] != ""
        letters = axes_letters(sp, letter)
        (amin, amax), (namin, namax), (famin, famax) = map(l -> axis_limits(sp, l), letters)
        n0, n1 = letter === :y ? (namax, namin) : (namin, namax)

        GR.savestate()
        gr_set_font(
            guidefont(ax),
            sp,
            halign = (:left, :hcenter, :right)[sign(ax[:rotation]) + 2],
            valign = ax[:mirror] ? :bottom : :top,
            rotation = ax[:rotation],
            # color = ax[:guidefontcolor],
        )
        ag = 0.5(amin + amax)
        ng = ax[:mirror] ? n1 : n0
        fg = ax[:mirror] ? famax : famin
        x, y = gr_w3tondc(sort_3d_axes(ag, ng, fg, letter)...)
        if letter in (:x, :y)
            h = gr_axis_height(sp, ax)
            x_offset = letter === :x ? -h : h
            y_offset = -h
        else
            x_offset = -0.03 - gr_axis_width(sp, ax)
            y_offset = 0
        end
        letter === :z && GR.setcharup(-1, 0)
        sgn = ax[:mirror] ? -1 : 1
        gr_text(x + sgn * x_offset, y + sgn * y_offset, ax[:guide])
        GR.restorestate()
    end

gr_add_title(sp, vp_plt, vp_sp) =
    if (title = sp[:title]) != ""
        GR.savestate()
        xpos, ypos, halign, valign = if (loc = sp[:titlelocation]) === :left
            xmin(vp_plt), ymax(vp_sp), :left, :top
        elseif loc === :center
            xcenter(vp_plt), ymax(vp_sp), :center, :top
        elseif loc === :right
            xmax(vp_plt), ymax(vp_sp), :right, :top
        else
            xposition(vp_plt, loc[1]),
            yposition(vp_plt, loc[2]),
            sp[:titlefonthalign],
            sp[:titlefontvalign]
        end
        gr_set_font(titlefont(sp), sp; halign, valign)
        gr_text(xpos, ypos, title)
        GR.restorestate()
    end

## Series

function gr_add_series(sp, series)
    # update the current stored gradient
    gr_set_gradient(series)

    GR.savestate()

    x, y, z = map(letter -> handle_surface(series[letter]), (:x, :y, :z))
    xscale, yscale = sp[:xaxis][:scale], sp[:yaxis][:scale]
    frng = series[:fillrange]

    # recompute data
    if ispolar(sp) && z === nothing
        extrema_r = gr_y_axislims(sp)
        if frng !== nothing
            _, frng = convert_to_polar(x, frng, extrema_r)
        end
        x, y = convert_to_polar(x, y, extrema_r)
    end

    # add custom frame shapes to markershape?
    series_annotations_shapes!(series)
    # -------------------------------------------------------

    gr_is3d(sp) && gr_set_projectiontype(sp)

    # draw the series
    clims = gr_clims(sp, series)
    if (st = series[:seriestype]) in (:path, :scatter, :straightline)
        if st === :straightline
            x, y = straightline_data(series)
        end
        gr_draw_segments(series, x, y, nothing, frng, clims)
        if series[:markershape] !== :none
            gr_draw_markers(series, x, y, nothing, clims)
        end
    elseif st === :shape
        gr_draw_shapes(series, clims)
    elseif st in (:path3d, :scatter3d)
        gr_draw_segments(series, x, y, z, nothing, clims)
        if st === :scatter3d || series[:markershape] !== :none
            gr_draw_markers(series, x, y, z, clims)
        end
    elseif st === :contour
        gr_draw_contour(series, x, y, z, clims)
    elseif st in (:surface, :wireframe, :mesh3d)
        GR.setwindow(-1, 1, -1, 1)
        gr_draw_surface(series, x, y, z, clims)
    elseif st === :volume
        sp[:legend_position] = :none
        GR.gr3.clear()
    elseif st === :heatmap
        # `z` is already transposed, so we need to reverse before passing its size.
        x, y = heatmap_edges(x, xscale, y, yscale, reverse(size(z)), ispolar(series))
        gr_draw_heatmap(series, x, y, z, clims)
    elseif st === :image
        gr_draw_image(series, x, y, z, clims)
    end

    # this is all we need to add the series_annotations text
    for (xi, yi, str, fnt) in EachAnn(series[:series_annotations], x, y)
        gr_set_font(fnt, sp)
        gr_text(GR.wctondc(xi, yi)..., str)
    end

    if sp[:legend_position] === :inline && should_add_to_legend(series)
        gr_set_textcolor(plot_color(sp[:legend_font_color]))
        offset, halign, valign = if sp[:yaxis][:mirror]
            _, i = sp[:xaxis][:flip] ? findmax(x) : findmin(x)
            -0.01, :right, :center
        else
            _, i = sp[:xaxis][:flip] ? findmin(x) : findmax(x)
            +0.01, :left, :center
        end
        gr_set_font(legendfont(sp), sp; halign, valign)
        x_l, y_l = GR.wctondc(x[i], y[i])
        gr_text(x_l + offset, y_l, series[:label])
    end
    GR.restorestate()
end

function gr_draw_segments(series, x, y, z, fillrange, clims)
    (x === nothing || length(x) ≤ 1) && return
    if fillrange !== nothing  # prepare fill-in
        GR.setfillintstyle(GR.INTSTYLE_SOLID)
        fr_from, fr_to = is_2tuple(fillrange) ? fillrange : (y, fillrange)
    end

    # draw the line(s)
    st = series[:seriestype]
    for segment in series_segments(series, st; check = true)
        i, rng = segment.attr_index, segment.range
        isempty(rng) && continue
        is3d = st === :path3d && z !== nothing
        is2d = st === :path || st === :straightline
        if is2d && fillrange !== nothing
            (fc = get_fillcolor(series, clims, i)) |> gr_set_fillcolor
            gr_set_fillstyle(get_fillstyle(series, i))
            fx = _cycle(x, vcat(rng, reverse(rng)))
            fy = vcat(_cycle(fr_from, rng), _cycle(fr_to, reverse(rng)))
            gr_set_transparency(fc, get_fillalpha(series, i))
            GR.fillarea(fx, fy)
        end
        (lc = get_linecolor(series, clims, i)) |> gr_set_fillcolor
        gr_set_line(get_linewidth(series, i), get_linestyle(series, i), lc, series)
        gr_set_transparency(lc, get_linealpha(series, i))
        if is3d
            GR.polyline3d(x[rng], y[rng], z[rng])
        elseif is2d
            arrowside, arrowstyle = if (arrow = series[:arrow]) isa Arrow
                arrow.side, arrow.style
            else
                :none, :simple
            end
            gr_polyline(x[rng], y[rng]; arrowside = arrowside, arrowstyle = arrowstyle)
        end
    end
end

function gr_draw_markers(
    series::Series,
    x,
    y,
    z,
    clims,
    msize = series[:markersize],
    strokewidth = series[:markerstrokewidth],
)
    isempty(x) && return
    GR.setfillintstyle(GR.INTSTYLE_SOLID)
    (shapes = series[:markershape]) === :none && return
    for segment in series_segments(series, :scatter)
        i = segment.attr_index
        rng = intersect(eachindex(x), segment.range)
        isempty(rng) && continue
        ms = get_thickness_scaling(series) * _cycle(msize, i)
        msw = get_thickness_scaling(series) * _cycle(strokewidth, i)
        shape = _cycle(shapes, i)
        for j in rng
            gr_draw_marker(
                series,
                _cycle(x, j),
                _cycle(y, j),
                _cycle(z, j),
                clims,
                i,
                ms,
                msw,
                shape,
            )
        end
    end
end

function gr_draw_shapes(series, clims)
    x, y = shape_data(series)
    for segment in series_segments(series, :shape)
        i, rng = segment.attr_index, segment.range
        if length(rng) > 1
            # connect to the beginning
            rng = vcat(rng, rng[1])

            # get the segments
            xseg, yseg = x[rng], y[rng]

            # draw the interior
            fc = get_fillcolor(series, clims, i)
            gr_set_fill(fc)
            fs = get_fillstyle(series, i)
            gr_set_fillstyle(fs)
            gr_set_transparency(fc, get_fillalpha(series, i))
            GR.fillarea(xseg, yseg)

            # draw the shapes
            lc = get_linecolor(series, clims, i)
            gr_set_line(get_linewidth(series, i), get_linestyle(series, i), lc, series)
            gr_set_transparency(lc, get_linealpha(series, i))
            GR.polyline(xseg, yseg)
        end
    end
end

function gr_draw_contour(series, x, y, z, clims)
    GR.setprojectiontype(0)
    GR.setspace(clims[1], clims[2], 0, 90)
    gr_set_line(get_linewidth(series), get_linestyle(series), get_linecolor(series), series)
    gr_set_transparency(get_fillalpha(series))
    h = gr_contour_levels(series, clims)
    if series[:fillrange] !== nothing
        GR.contourf(x, y, h, z, series[:contour_labels] == true ? 1 : 0)
    else
        black = plot_color(:black)
        coff = plot_color(series[:linecolor]) in (black, [black]) ? 0 : 1_000
        GR.contour(x, y, h, z, coff + (series[:contour_labels] == true ? 1 : 0))
    end
end

function gr_draw_surface(series, x, y, z, clims)
    e_kwargs = series[:extra_kwargs]
    if (st = series[:seriestype]) === :surface
        if ndims(x) == ndims(y) == ndims(z) == 2
            GR.gr3.surface(x', y', z, GR.OPTION_3D_MESH)
        else
            fillalpha = get_fillalpha(series)
            fillcolor = get_fillcolor(series)
            # NOTE: setting nx = 0 or ny = 0 disables GR.gridit interpolation
            nx, ny = get(e_kwargs, :nx, 200), get(e_kwargs, :ny, 200)
            if length(x) == length(y) == length(z) && nx > 0 && ny > 0
                x, y, z = GR.gridit(x, y, z, nx, ny)
            end
            d_opt = get(e_kwargs, :display_option, GR.OPTION_COLORED_MESH)
            if (!isnothing(fillalpha) && fillalpha < 1) || alpha(first(fillcolor)) < 1
                gr_set_transparency(fillcolor, fillalpha)
                GR.surface(x, y, z, d_opt)
            else
                GR.gr3.surface(x, y, z, d_opt)
            end
        end
    elseif st === :wireframe
        GR.setfillcolorind(0)
        GR.surface(x, y, z, get(e_kwargs, :display_option, GR.OPTION_FILLED_MESH))
    elseif st === :mesh3d
        if series[:connections] isa AbstractVector{<:AbstractVector{Int}}
            # Combination of any polygon types
            cns = map(cns -> [length(cns), cns...], series[:connections])
        elseif series[:connections] isa AbstractVector{NTuple{N,Int}} where {N}
            # Only N-gons - connections have to be 1-based (indexing)
            N = length(series[:connections][1])
            cns = map(cns -> [N, cns...], series[:connections])
        elseif series[:connections] isa NTuple{3,<:AbstractVector{Int}}
            # Only triangles - connections have to be 0-based (indexing)
            ci, cj, ck = series[:connections]
            if !(length(ci) == length(cj) == length(ck))
                "Argument connections must consist of equally sized arrays." |>
                ArgumentError |>
                throw
            end
            cns = map(i -> ([3, ci[i] + 1, cj[i] + 1, ck[i] + 1]), eachindex(ci))
        else
            "Unsupported `:connections` type $(typeof(series[:connections])) for seriestype=$st" |>
            ArgumentError |>
            throw
        end
        facecolor = if series[:fillcolor] isa AbstractArray
            series[:fillcolor]
        else
            fill(series[:fillcolor], length(cns))
        end
        fillalpha = get_fillalpha(series)
        facecolor = map(fc -> set_RGBA_alpha(fillalpha, fc), facecolor)
        GR.setborderwidth(get_linewidth(series))
        GR.setbordercolorind(gr_getcolorind(get_linecolor(series)))
        GR.polygonmesh3d(x, y, z, vcat(cns...), signed.(gr_color.(facecolor)))
    else
        throw(ArgumentError("Not handled !"))
    end
end

function gr_draw_heatmap(series, x, y, z, clims)
    fillgrad = _as_gradient(series[:fillcolor])
    GR.setprojectiontype(0)
    GR.setspace(clims..., 0, 90)
    w, h = length(x) - 1, length(y) - 1
    sp = series[:subplot]
    if !ispolar(series) && is_uniformly_spaced(x) && is_uniformly_spaced(y)
        # For uniformly spaced data use GR.drawimage, which can be
        # much faster than GR.nonuniformcellarray, especially for
        # pdf output, and also supports alpha values.
        # Note that drawimage draws uniformly spaced data correctly
        # even on log scales, where it is visually non-uniform.
        colors, _z = if sp[:colorbar_scale] === :identity
            plot_color.(get(fillgrad, z, clims), series[:fillalpha]), z
        elseif sp[:colorbar_scale] === :log10
            z_log = replace(x -> isinf(x) ? NaN : x, log10.(z))
            z_normalized = get_z_normalized.(z_log, log10.(clims)...)
            plot_color.(map(z -> get(fillgrad, z), z_normalized), series[:fillalpha]), z_log
        end
        for i in eachindex(colors)
            isnan(_z[i]) && (colors[i] = set_RGBA_alpha(0, colors[i]))
        end
        GR.drawimage(first(x), last(x), last(y), first(y), w, h, gr_color.(colors))
    else
        if something(series[:fillalpha], 1) < 1
            @warn "GR: transparency not supported in non-uniform heatmaps. Alpha values ignored."
        end
        z_normalized, _z = if sp[:colorbar_scale] === :identity
            get_z_normalized.(z, clims...), z
        elseif sp[:colorbar_scale] === :log10
            z_log = replace(x -> isinf(x) ? NaN : x, log10.(z))
            get_z_normalized.(z_log, log10.(clims)...), z_log
        end
        rgba = map(x -> round(Int32, 1_000 + 255x), z_normalized)
        bg_rgba = gr_getcolorind(plot_color(series[:subplot][:background_color_inside]))
        for i in eachindex(rgba)
            isnan(_z[i]) && (rgba[i] = bg_rgba)
        end
        if ispolar(series)
            y[1] < 0 && @warn "'y[1] < 0' (rmin) is not yet supported."
            dist = min(gr_x_axislims(sp)[2], gr_y_axislims(sp)[2])
            GR.setwindow(-dist, dist, -dist, dist)  # square ar
            GR.nonuniformpolarcellarray(rad2deg.(x), y, w, h, rgba)
        else
            GR.nonuniformcellarray(x, y, w, h, rgba)
        end
    end
end

function gr_draw_image(series, x, y, z, clims)
    x_min, x_max = ignorenan_extrema(x)
    y_min, y_max = ignorenan_extrema(y)
    GR.drawimage(x_min, x_max, y_max, y_min, size(z)..., gr_color.(z))
end

# ----------------------------------------------------------------

for (mime, fmt) in (
    "application/pdf" => "pdf",
    "image/png" => "png",
    "application/postscript" => "ps",
    "image/svg+xml" => "svg",
)
    @eval function _show(io::IO, ::MIME{Symbol($mime)}, plt::Plot{GRBackend})
        dpi_factor = $fmt == "png" ? plt[:dpi] / Plots.DPI : 1
        filepath = tempname() * "." * $fmt
        GR.emergencyclosegks()
        withenv(
            "GKS_FILEPATH" => filepath,
            "GKS_ENCODING" => "utf8",
            "GKSwstype" => $fmt,
        ) do
            gr_display(plt, dpi_factor)
        end
        GR.emergencyclosegks()
        write(io, read(filepath, String))
        rm(filepath)
    end
end

function _display(plt::Plot{GRBackend})
    if plt[:display_type] === :inline
        filepath = tempname() * ".pdf"
        GR.emergencyclosegks()
        withenv(
            "GKS_FILEPATH" => filepath,
            "GKS_ENCODING" => "utf8",
            "GKSwstype" => "pdf",
        ) do
            gr_display(plt)
        end
        GR.emergencyclosegks()
        println(
            "\033]1337;File=inline=1;preserveAspectRatio=0:",
            base64encode(open(read, filepath)),
            "\a",
        )
        rm(filepath)
    else
        withenv("GKS_ENCODING" => "utf8", "GKS_DOUBLE_BUF" => true) do
            gr_display(plt)
        end
    end
end

closeall(::GRBackend) = GR.emergencyclosegks()

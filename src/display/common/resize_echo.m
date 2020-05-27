
function resize_echo(main_figure,evt)

pix_pos=getpixelposition(main_figure);
pan_height=get_top_panel_height(8.25);

echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
opt_panel=getappdata(main_figure,'option_tab_panel');
algo_panel=getappdata(main_figure,'algo_tab_panel');
info_panel_comp=getappdata(main_figure,'Info_panel');
load_bar_comp=getappdata(main_figure,'Loading_bar');

inf_h_1=load_bar_comp.panel.Position(4);
inf_h_2=info_panel_comp.info_panel.Position(4);
inf_h=inf_h_1+inf_h_2;

try
    set(load_bar_comp.panel,'Position',[0 0 pix_pos(3) inf_h_1]);
    set(info_panel_comp.info_panel,'Position',[0 inf_h_1 pix_pos(3) inf_h_2]);
    set(opt_panel,'Position',[0 pix_pos(4)-pan_height 0.5*pix_pos(3) pan_height]);
    set(algo_panel,'Position',[0.5*pix_pos(3) pix_pos(4)-pan_height 0.5*pix_pos(3) pan_height]);
    set(echo_tab_panel,'Position',[0 inf_h pix_pos(3) pix_pos(4)-pan_height-inf_h]);
catch err
   print_errors_and_warnings(1,'warning',err) ;
end

%load_bar_comp=getappdata(main_figure,'Loading_bar');
%load_bar_comp.status_bar.paintAll();
end
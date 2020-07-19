function resize_mini_ax(src,~,main_figure)
set(src,'SizeChangedFcn',{}); 
if~isdeployed
    disp('Resize Mini Ax');
end
load_mini_axes(main_figure,src,[0 0 1 1]);
set(src,'SizeChangedFcn',{}); 
update_axis(main_figure,1,'main_or_mini','mini');
update_grid_mini_ax(main_figure);
set_alpha_map(main_figure,'main_or_mini','mini')
update_cmap(main_figure);
display_bottom(main_figure);
display_regions('mini');
init_link_prop(main_figure);
set(src,'SizeChangedFcn',{@resize_mini_ax,main_figure}); 

end
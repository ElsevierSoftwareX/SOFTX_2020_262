function order_option_tab(main_figure)
tab_group=getappdata(main_figure,'option_tab_panel');

tags={tab_group.Children(:).Tag};

tag_order={'disp' 'laylist' 'map' 'proc' 'cal' 'env' 'reglist' 'sv_f' 'st_tracks' 'ts_f' 'lines'};
tag_order(~ismember(tag_order,tags))=[];
idx=cellfun(@(x) find(strcmpi(x,tags)),tag_order);

tab_group.Children=tab_group.Children(idx);

drawnow;
end
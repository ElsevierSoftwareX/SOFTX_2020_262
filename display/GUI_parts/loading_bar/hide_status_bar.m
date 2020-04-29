function hide_status_bar(main_figure)

if isempty(main_figure)
    return;
end

load_bar_comp=getappdata(main_figure,'Loading_bar');

if ~isempty(load_bar_comp)
   load_bar_comp.progress_bar.setText('');
   load_bar_comp.progress_bar.setVisible(0); 
   set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',1, 'Value',0);
end
drawnow;

end
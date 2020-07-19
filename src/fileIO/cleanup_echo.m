function cleanup_echo(main_figure)

if ~isempty(main_figure)
    close_figures_callback([],[],main_figure);
end

esp3_obj=getappdata(groot,'esp3_obj');
delete(esp3_obj);
%delete(main_figure);
if isdeployed()
    obj=findobj(groot,'Type','Figure');
    if ~isempty(obj)
        delete(obj);
    end
end




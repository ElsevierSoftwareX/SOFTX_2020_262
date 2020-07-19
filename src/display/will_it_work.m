function bool_func = will_it_work(parent_h,ver_num,ui_or_not_ui)
bool_func_ui = true;
bool_func_num = true;

if ~isempty(parent_h)
    if ui_or_not_ui
        bool_func_ui = matlab.ui.internal.isUIFigure(ancestor(parent_h,'figure')); 
    else
        bool_func_ui = ~matlab.ui.internal.isUIFigure(ancestor(parent_h,'figure')); 
    end
end

if ~isempty(ver_num)
    cur_ver=ver('Matlab');
    bool_func_num = str2double(cur_ver.Version)>=ver_num;
end

bool_func = bool_func_ui && bool_func_num;
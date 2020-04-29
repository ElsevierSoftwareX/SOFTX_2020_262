function [answers,cancel]=input_dlg_perso(main_figure,tt_str,cell_input,cell_fmt_input,cell_default_value,varargin)

if ~isempty(main_figure)
    curr_disp=get_esp3_prop('curr_disp');
    if ~isempty(curr_disp)
        font=curr_disp.Font;
        cmap=curr_disp.Cmap;
    else
        font=[];
        cmap=[];
    end
else
    font=[];
    cmap=[];
end

opt={'Ok' 'Cancel'};
nb_lines=numel(cell_input);
cancel=1;
answers=cell_default_value;

str_b_w=nanmax(cellfun(@(x) ceil(numel(x)*8),cell_input));
str_b_w=nanmax(str_b_w,120);

bt_w=nanmax([nansum(cellfun(@numel,opt))*8,50]);

box_w=nanmax(str_b_w+20,numel(opt)*(bt_w+10)+10);

ht=17;

QuestFig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w 100+(2*nb_lines-1)*ht],...
    'WindowStyle','modal','Visible','on','resize','off','tag','question','Name',tt_str,'UserData',opt{2});%,'CloseRequestFcn',@do_nothing);
for i=1:nb_lines
    uicontrol('Parent',QuestFig,...
        'Style','text',...
        'Position',[(box_w-str_b_w)/2 40+(2*i+1)*ht str_b_w ht],...
        'String',cell_input{i},'HorizontalAlignment','Left');
    switch cell_fmt_input{i}
        case {'%s' '%c'}
            x_val=cell_default_value{i};
        otherwise
            x_val=num2str(cell_default_value{i},cell_fmt_input{i});
    end
    answers_h(i)=uicontrol('Parent',QuestFig,...
        'Style','edit',...
        'Position',[(box_w-str_b_w)/2 40+(2*i)*ht str_b_w ht],...
        'String',x_val,'Callback',{@update_answers,-inf,inf,cell_default_value,cell_fmt_input{i},i});   
end

for i=1:numel(opt)
    noHandle(i)=uicontrol('Parent',QuestFig,...
        'Position',[(box_w-2*bt_w-10)/2+(bt_w+10)*(i-1) 20 bt_w 25],...
        'String',opt{i},...
        'Callback',@decision_callback,...
        'KeyPressFcn',@doControlKeyPress , 'UserData',0);
end
QuestFig.UserData=answers;
setdefaultbutton(QuestFig, noHandle);
format_color_gui(QuestFig,font,cmap);
drawnow;


if ishghandle(QuestFig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    uiwait(QuestFig);
    delete(c);
end

if ishghandle(QuestFig)
    answers=get(QuestFig,'UserData');
    cancel=noHandle(2).UserData;
end
delete(QuestFig);
drawnow; % Update the view to remove the closed figure (g1031998)

end
function update_answers(src,evt,min_val,max_val,deflt_val,precision,i)
check_fmt_box(src,[],min_val,max_val,deflt_val,precision);
    switch precision
        case {'%s' '%c'}
            x_val=src.String;
        otherwise
            x_val=str2double(src.String);
    end
src.Parent.UserData{i}=x_val;

end

function decision_callback(obj, evd) %#ok
obj.UserData=1;
uiresume(gcbf);
end

function doControlKeyPress(obj, evd)
switch(evd.Key)
    case {'return'}
        set(gcbf,'UserData',get(obj,'String'));
        uiresume(gcbf);
    case 'escape'
        delete(gcbf)
end
end

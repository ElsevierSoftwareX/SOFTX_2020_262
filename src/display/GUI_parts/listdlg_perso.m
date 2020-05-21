function [select,val]=listdlg_perso(main_figure,tt_str,str_list,varargin)
select=[];
val=0;

p = inputParser;

addRequired(p,'main_figure',@(h) isempty(h)|isa(h,'matlab.ui.Figure'));
addRequired(p,'tt_str',@ischar);
addRequired(p,'str_list',@iscell);
addParameter(p,'init_val',1:numel(str_list),@isnumeric);
addParameter(p,'timeout',[],@isnumeric);

parse(p,main_figure,tt_str,str_list,varargin{:});


curr_disp = get_esp3_prop('curr_disp');
if ~isempty(curr_disp)
    font=curr_disp.Font;
    cmap=curr_disp.Cmap;
else
    font=[];
    cmap=[];
end

if isempty(main_figure)
    main_figure=get_esp3_prop('main_figure');
end

opt={'OK' 'Cancel'};

init_val=p.Results.init_val;
switch get(groot,'units')
    case 'pixels'
        ss = get(groot,'screensize');
    case 'normalized'
   ss= [0 0 inf inf];     
end

s_str=nanmax(cellfun(@numel,deblank(str_list)));

str_b_w=nanmin(nanmax(s_str*8,200),600);
str_b_h=numel(str_list)*10+20;

str_b_h=nanmin(nanmax(str_b_h,80),ceil(ss(4)/4*3));

bt_w=nanmax([cellfun(@(x) numel(x*8),opt),50]);

box_w=str_b_w+20;
box_h=str_b_h+45;


if isdeployed()
    style='modal';
else
    style='normal';
end

list_fig=new_echo_figure(main_figure,'units','pixels','position',[200 200 box_w box_h],...
    'WindowStyle',style,'Visible','off','resize','off','tag','listbox','Name',tt_str,'CloseRequestFcn',@do_nothing,'UserData','OK');

listbox=uicontrol('Parent',list_fig,...
    'Style','listbox',...
    'Min',0,'Max',10,...
    'Value',init_val,...
    'Position',[(box_w-str_b_w)/2 45 str_b_w str_b_h],...
    'String',str_list);

optH=gobjects(1,numel(opt));

for uio=1:numel(opt)
optH(uio)=uicontrol('Parent',list_fig,...
    'Position',[(box_w-numel(opt)*bt_w-10)/2+(uio-1)*(bt_w+10) 10 bt_w 25],...
    'String',opt{uio},...
    'Callback',@decision_callback,...
    'KeyPressFcn',@doControlKeyPress , 'Value',0);
end
list_fig.Visible='on';
setdefaultbutton(list_fig, optH(1));
format_color_gui(list_fig,font,cmap);
drawnow;

if ishghandle(list_fig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    if isempty(p.Results.timeout)
        uiwait(list_fig);
    else
        uiwait(list_fig,p.Results.timeout);
    end
    delete(c);
end
switch get(list_fig,'UserData')
    case 'OK'
        select=get(listbox,'Value');
        val=1;
end

delete(list_fig);
drawnow; % Update the view to remove the closed figure (g1031998)

end
function decision_callback(obj, evd) %#ok
  set(gcbf,'UserData',get(obj,'String'));
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

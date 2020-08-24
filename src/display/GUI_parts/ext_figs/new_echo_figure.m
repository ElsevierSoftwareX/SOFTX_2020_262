function fig_handle=new_echo_figure(main_figure,varargin)


def_pos=[0.2 0.2 0.6 0.6];

size_max = get(groot, 'MonitorPositions');
units= get(groot, 'units');
if ~isempty(main_figure)
    pos_main=getpixelposition(main_figure);
else
    pos_main=size_max(1,:);
end
[~,id_screen]=nanmin(abs(size_max(:,1)-pos_main(1)));
if size(size_max,1)>1
    
    size_max(id_screen,:)=[];
end

def_pos=def_pos.*[size_max(end,3:4) size_max(end,3:4)];

def_menubar='none';
def_toolbar='none';

p = inputParser;
addRequired(p,'main_figure',@(x) isempty(x)||ishandle(x));
addParameter(p,'fig_handle',[],@(x) isempty(x)||ishandle(x));
addParameter(p,'Name','',@ischar);
addParameter(p,'Position',def_pos,@isnumeric);
addParameter(p,'Units','pixels',@ischar);
addParameter(p,'Color','White');
addParameter(p,'MenuBar',def_menubar,@ischar);
addParameter(p,'Toolbar',def_toolbar,@ischar);
addParameter(p,'Resize','on',@ischar);
addParameter(p,'CloseRequestFcn',@close_win_echo,@(x) isa(x,'function_handle'));
addParameter(p,'WindowScrollWheelFcn',@do_nothing,@(x) isa(x,'function_handle'));
addParameter(p,'ButtonDownFcn',@do_nothing,@(x) isa(x,'function_handle'));
addParameter(p,'WindowKeyPressFcn',@do_nothing,@(x) isa(x,'function_handle'));
addParameter(p,'WindowStyle','normal',@ischar);
addParameter(p,'Group','ESP3',@ischar);
addParameter(p,'Visible','on',@ischar);
addParameter(p,'WhichScreen','same',@ischar);
addParameter(p,'UserData',[]);
addParameter(p,'Tag','',@ischar);
addParameter(p,'Cmap','',@ischar);
addParameter(p,'Keep_old',0,@isnumeric);
addParameter(p,'UiFigureBool',false,@islogical);

parse(p,main_figure,varargin{:});


if p.Results.Keep_old==0
    hfigs=clean_echo_figures(main_figure,'Tag',p.Results.Tag);
else
    hfigs=getappdata(main_figure,'ExternalFigures');
end

switch lower(p.Results.Units)
    case 'pixels'
        pos_final=p.Results.Position+[size_max(end,1:2) 0 0];
        pos_u='pixels';
    case {'normalized' 'norm'}
        pos_u=units;
        pos_final=p.Results.Position.*[size_max(end,3:4) size_max(end,3:4)]+[size_max(end,1:2) 0 0];
    otherwise
        pos_u='pixels';
        pos_final=p.Results.Position;
end

switch p.Results.Toolbar
    case 'esp3'
        tbar='none';
    otherwise
        tbar=p.Results.Toolbar;
end

switch p.Results.MenuBar
    case 'esp3'
        mbar='none';
    otherwise
        mbar=p.Results.MenuBar;
end

if isempty(p.Results.fig_handle)
    if p.Results.UiFigureBool
        fig_handle=uifigure('Units',pos_u,...
            'Position',pos_final,...
            'Color',p.Results.Color,...
            'Tag',p.Results.Tag,...
            'Name',p.Results.Name,...
            'NumberTitle','off',...
            'Resize',p.Results.Resize,...
            'MenuBar',mbar,...
            'ToolBar',tbar,...
            'CloseRequestFcn',p.Results.CloseRequestFcn,...
            'ButtonDownFcn',p.Results.ButtonDownFcn,...
            'WindowScrollWheelFcn',p.Results.WindowScrollWheelFcn,...
            'Visible',p.Results.Visible,...
            'WindowKeyPressFcn',p.Results.WindowKeyPressFcn,...
            'UserData',p.Results.UserData);
    else
        fig_handle=figure('Units',pos_u,...
            'InvertHardcopy', 'off',...
            'Position',pos_final,...
            'Color',p.Results.Color,...
            'Tag',p.Results.Tag,...
            'DockControls','off',...
            'WindowStyle',p.Results.WindowStyle,...
            'Name',p.Results.Name,...
            'NumberTitle','off',...
            'Resize',p.Results.Resize,...
            'MenuBar',mbar,...
            'ToolBar',tbar,...
            'CloseRequestFcn',p.Results.CloseRequestFcn,...
            'ButtonDownFcn',p.Results.ButtonDownFcn,...
            'WindowScrollWheelFcn',p.Results.WindowScrollWheelFcn,...
            'Visible',p.Results.Visible,...
            'WindowKeyPressFcn',p.Results.WindowKeyPressFcn,...
            'UserData',p.Results.UserData);
    end
else
    fig_handle=p.Results.fig_handle;
    fields_in=fieldnames(p.Results);
    fig_handle.NumberTitle='off';
    fig_handle.Color='White';
    for ifi=1:length(fields_in)
        if ~any(strcmp(fields_in{ifi},p.UsingDefaults))&&isprop(fig_handle,fields_in{ifi})
            try
                set(fig_handle,fields_in{ifi},p.Results.(fields_in{ifi}));
            catch
                fprintf('Could not use this value %s for figure propertie %s',p.Results.(fields_in{ifi}),fields_in{ifi}\n);
            end
        end
    end
end

if isdeployed()
    fig_handle.DockControls='off';
end

iptPointerManager(fig_handle);

switch p.Results.Toolbar
    case 'esp3'
        create_default_toolbar(fig_handle);
end

%% Install mouse pointer manager in figure
iptPointerManager(fig_handle);
if will_it_work(fig_handle,[],false)
    javaFrame = get(fig_handle,'JavaFrame');
    javaFrame.setFigureIcon(javax.swing.ImageIcon(fullfile(whereisEcho(),'icons','echoanalysis.png')));
    if ~isdeployed()
        javaFrame.fHG2Client.setClientDockable(true);
        set(javaFrame,'GroupName',p.Results.Group);
    end
elseif will_it_work(fig_handle,9.9,true)
    fig_handle.Icon = fullfile(whereisEcho(),'icons','echoanalysis.png');
end


if ~isempty(main_figure)
    curr_disp=get_esp3_prop('curr_disp');
    if ~isempty(curr_disp)
        font=curr_disp.Font;
        if ismember('Cmap',p.UsingDefaults)
            cmap=curr_disp.Cmap;
        else
            cmap=p.Results.Cmap;
        end
    else
        font=[];
        cmap=p.Results.Cmap;
    end
else
    font=[];
    cmap=p.Results.Cmap;
end

if ~strcmp(fig_handle.WindowStyle,'docked')
    switch lower(p.Results.Units)
        case {'normalized' 'norm' 'pixels'}
            set(fig_handle,'Position',get_dlg_position(main_figure,pos_final,get(fig_handle,'Units'),p.Results.WhichScreen));
    end
end

if~isempty(font)
    if ~strcmp(fig_handle.Tag,'font_choice')
        
        text_obj=findobj(fig_handle,'-property','FontName');
        
        set(text_obj,'FontName',font);
    end
    
end

if ~isempty(main_figure)
    hfigs=[hfigs fig_handle];
    setappdata(main_figure,'ExternalFigures',hfigs);
end
end



function close_win_echo(src,~)
uiresume(src);

delete(src);
end
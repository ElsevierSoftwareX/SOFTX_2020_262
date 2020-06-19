function gui_fmt=init_gui_fmt_struct(varargin)

% gui_fmt.x_sep=10;
% gui_fmt.y_sep=5;
% gui_fmt.txt_w=110;
% gui_fmt.txt_h=25;
% gui_fmt.box_w=40;
% gui_fmt.box_h=30;
% gui_fmt.button_w=60;
% gui_fmt.button_h=30;
% 
% gui_fmt.txtStyle=struct('Style','text','units','pixels','HorizontalAlignment','right','BackgroundColor','white');
% gui_fmt.txtTitleStyle=struct('Style','text','units','pixels','HorizontalAlignment','center','BackgroundColor','white','Fontweight','Bold');
% gui_fmt.edtStyle=struct('Style','Edit','units','pixels','BackgroundColor','white');
% gui_fmt.pushbtnStyle=struct('Style','pushbutton','units','pixels');
% gui_fmt.chckboxStyle=struct('Style','checkbox','Units','pixels','BackgroundColor','white');
% gui_fmt.popumenuStyle=struct('Style','popupmenu','Units','pixels');
% gui_fmt.lstboxStyle=struct('Style','listbox','Units','pixels');
% gui_fmt.radbtnStyle=struct('Style','radiobutton','Units','pixels','BackgroundColor','white');

if isempty(varargin)
    units='characters';
else
    units=varargin{1};
end

switch units
    case{ 'characters','char'}
        gui_fmt.x_sep=0.5;
        gui_fmt.y_sep=0.25;
        gui_fmt.txt_w=20;
        gui_fmt.txt_h=1.2;
        gui_fmt.box_w=6.5;
        gui_fmt.box_h=1.2;
        gui_fmt.button_w=9;
        gui_fmt.button_h=1.2;
    case'pixels'
        gui_fmt.x_sep=4;
        gui_fmt.y_sep=5;
        gui_fmt.txt_w=95;
        gui_fmt.txt_h=20;
        gui_fmt.box_w=32;
        gui_fmt.box_h=25;
        gui_fmt.button_w=50;
        gui_fmt.button_h=25;
    case {'normalized','norm'}
        
        if nargin<3
            nw=2;
            nh=4;
        else
            nh=varargin{2};
            nw=varargin{3};
        end
        
        gui_fmt.x_sep=0.02;
        gui_fmt.y_sep=0.025;
        gui_fmt.txt_w=(1-(nw*3)*gui_fmt.x_sep)/nw*4/5;
        gui_fmt.txt_h=(1-(nh+1)*gui_fmt.y_sep)/nh*0.8;
        gui_fmt.box_w=(1-(nw*3)*gui_fmt.x_sep)/nw*1/5;
        gui_fmt.box_h=(1-(nh+1)*gui_fmt.y_sep)/nh;
        gui_fmt.button_w=(1-(nw*3)*gui_fmt.x_sep)/nw*1/2;
        gui_fmt.button_h=(1-(nh+1)*gui_fmt.y_sep)/nh;
end

gui_fmt.txtStyle=struct('Style','text','units',units,'HorizontalAlignment','right','BackgroundColor','white','fontsize',get(0,'defaultTextFontSize'));
gui_fmt.txtTitleStyle=struct('Style','text','units',units,'HorizontalAlignment','center','BackgroundColor','white','Fontweight','Bold','fontsize',get(0,'defaultTextFontSize'));
gui_fmt.edtStyle=struct('Style','Edit','units',units,'BackgroundColor','white','fontsize',get(0,'defaultTextFontSize'));
gui_fmt.pushbtnStyle=struct('Style','pushbutton','units',units,'fontsize',get(0,'defaultTextFontSize'));
gui_fmt.chckboxStyle=struct('Style','checkbox','Units',units,'BackgroundColor','white','fontsize',get(0,'defaultTextFontSize'));
gui_fmt.popumenuStyle=struct('Style','popupmenu','Units',units,'fontsize',get(0,'defaultTextFontSize'));
gui_fmt.lstboxStyle=struct('Style','listbox','Units',units,'fontsize',get(0,'defaultTextFontSize'));
gui_fmt.radbtnStyle=struct('Style','radiobutton','Units',units,'BackgroundColor','white','fontsize',get(0,'defaultTextFontSize'));
% 
% gui_fmt.x_sep=0.1;
% gui_fmt.y_sep=0.1;
% gui_fmt.txt_w=2;
% gui_fmt.txt_h=0.5;
% gui_fmt.box_w=1;
% gui_fmt.box_h=0.5;
% gui_fmt.button_w=3;
% gui_fmt.button_h=1.2;
% 
% gui_fmt.txtStyle=struct('Style','text','units','centimeters','HorizontalAlignment','right','BackgroundColor','white');
% gui_fmt.txtTitleStyle=struct('Style','text','units','centimeters','HorizontalAlignment','center','BackgroundColor','white','Fontweight','Bold');
% gui_fmt.edtStyle=struct('Style','Edit','units','centimeters','BackgroundColor','white');
% gui_fmt.pushbtnStyle=struct('Style','pushbutton','units','centimeters');
% gui_fmt.chckboxStyle=struct('Style','checkbox','Units','centimeters','BackgroundColor','white');
% gui_fmt.popumenuStyle=struct('Style','popupmenu','Units','centimeters');
% gui_fmt.lstboxStyle=struct('Style','listbox','Units','centimeters');
% gui_fmt.radbtnStyle=struct('Style','radiobutton','Units','centimeters','BackgroundColor','white');
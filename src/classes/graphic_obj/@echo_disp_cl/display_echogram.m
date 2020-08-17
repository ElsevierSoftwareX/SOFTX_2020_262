%% Function
function [dr,dp,up]=display_echogram(echo_obj,trans_obj,varargin)
up=0;
curr_disp_default=curr_state_disp_cl();

p = inputParser;
addRequired(p,'echo_obj',@(x) isa(x,'echo_disp_cl'));
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'curr_disp',curr_disp_default,@(x) isa(x,'curr_state_disp_cl'));
addParameter(p,'main_figure',[],@(x) isempty(x)||ishandle(x));
addParameter(p,'fieldname','sv',@ischar);
addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
addParameter(p,'x',[],@isnumeric);
addParameter(p,'y',[],@isnumeric);
addParameter(p,'force_update',true,@islogical);

parse(p,echo_obj,trans_obj,varargin{:});

% cur_ver=ver('Matlab');
% cur_ver_num = str2double(cur_ver.Version);

curr_disp = p.Results.curr_disp;

x = p.Results.x;
y = p.Results.y;
echo_obj = p.Results.echo_obj;

fieldname = p.Results.fieldname;

force_update = p.Results.force_update;


switch class(echo_obj.main_ax.Parent)
    case 'matlab.ui.container.Tab'
        if ~strcmpi(echo_obj.main_ax.Tag,'mini')
            echo_obj.main_ax.Parent.Title = sprintf('%s: %.0f kHz %s',curr_disp.Type,trans_obj.Config.Frequency/1e3,trans_obj.Config.ChannelID);
        end
    case 'matlab.ui.Figure'
        if isempty(echo_obj.main_ax.Parent.Name)
            echo_obj.main_ax.Parent.Name = sprintf('%s: %.0f kHz %s',curr_disp.Type,trans_obj.Config.Frequency,trans_obj.Config.ChannelID);
        end
end


ax = echo_obj.main_ax;
echo_h = echo_obj.echo_surf;

xdata=trans_obj.get_transceiver_pings();
ydata=trans_obj.get_transceiver_samples();

if isempty(x)
    x = xdata;
end

if isempty(y)
    y = ydata;
end

idx_ping_min=find((xdata-x(1)>=0),1);
idx_r_min=find((ydata-y(1)>=0),1);
idx_ping_max=find((xdata-x(end)>=0),1);
idx_r_max=find((ydata-y(end)>=0),1);

if isempty(idx_r_min)
    idx_r_min=1;
end

if y(end)==Inf||isempty(idx_r_max)
    idx_r_max=length(ydata);
end

if isempty(idx_ping_min)
    idx_ping_min=1;
end

if isempty(idx_ping_max)
    idx_ping_max=length(xdata);
end

idx_ping=idx_ping_min:idx_ping_max;

screensize = getpixelposition(ax);

if all(isinf(x))
    idx_ping=idx_ping(1:floor(nanmin(screensize(3),length(idx_ping))));
end
%screen_ratio=(screensize(3)/screensize(4));

idx_r=(idx_r_min:idx_r_max)';

nb_samples=length(idx_r);
nb_pings=length(idx_ping);

[dr,dp]=get_dr_dp(ax,nb_samples,nb_pings,curr_disp.EchoQuality,echo_h.Type);

% profile on;

idx_r_red_ori=(idx_r(1:dr:end));
idx_ping_red_ori=idx_ping(1):dp:idx_ping(end);

if force_update==0
    update_echo=echo_obj.get_update_echo(p.Results.Unique_ID,trans_obj.Config.ChannelID,fieldname,idx_r_red_ori,idx_ping_red_ori,dr,dp);
else
    update_echo=1;
end


if update_echo>0
    
    %     mem_struct=memory;
    %     size_tot=ceil(mem_struct.MaxPossibleArrayBytes/(8*32));
    %     ip_size_max=(ceil(sqrt(size_tot))*sqrt(screen_ratio)-numel(numel(idx_ping_red_ori)))/2;
    %     ir_size_max=(ceil(sqrt(size_tot))/sqrt(screen_ratio)-numel(numel(idx_r_red_ori)))/2;
    %
    i_p=ceil(numel(idx_ping_red_ori)*curr_disp.Disp_dy_dx(2));
    %i_p=nanmax(ip_size_max,200)
    buffer_p=0:dp:i_p*dp;
    
    i_r=ceil(numel(idx_r_red_ori)*curr_disp.Disp_dy_dx(1));
    %i_r=nanmax(ir_size_max,200)
    buffer_r=0:dr:i_r*dr;
    
    %     buffer_r=[];
    %     buffer_p=[];
    
    idx_r_red=union(union(idx_r_red_ori,idx_r_red_ori(1)-buffer_r),idx_r_red_ori(end)+buffer_r);
    idx_r_red(idx_r_red<ydata(1)|idx_r_red>ydata(end))=[];
    
    idx_ping_red=union(union(idx_ping_red_ori,idx_ping_red_ori(1)-buffer_p),idx_ping_red_ori(end)+buffer_p);
    idx_ping_red(idx_ping_red<xdata(1)|idx_ping_red>xdata(end))=[];
    
    
    if ~isdeployed()
        fprintf('Pings to load %d to %d\n',idx_ping_red(1),idx_ping_red(end));
        fprintf('Pings to display %d to %d\n',idx_ping_red_ori(1),idx_ping_red_ori(end));
    end
    switch echo_obj.echo_usrdata.geometry_y
        case {'depth' 'range'}
            
            if strcmp(echo_obj.echo_usrdata.geometry_y,'depth') 
                depth_trans=trans_obj.get_transducer_depth(idx_ping_red);
            else
                depth_trans=zeros(1,numel(idx_r_red));
            end
            
            if any(depth_trans~=0)||trans_obj.Config.TransducerAlphaX~=0||trans_obj.Config.TransducerAlphaY~=0
                [x_data_disp,y_data_disp,data,sc]=trans_obj.apply_line_depth(fieldname,idx_r_red,idx_ping_red);
            else
                [data,sc]=trans_obj.Data.get_subdatamat(idx_r_red,idx_ping_red,'field',fieldname);
                x_data_disp=xdata(idx_ping_red);
                y_data_disp=trans_obj.get_transceiver_range(idx_r_red);
            end
            
        otherwise
            [data,sc]=trans_obj.Data.get_subdatamat(idx_r_red,idx_ping_red,'field',fieldname);
            
            x_data_disp=xdata(idx_ping_red);
            y_data_disp=ydata(idx_r_red);
    end
    
    if isempty(data)
        switch  fieldname
            case 'spdenoised'
                fieldname='sp';
            case 'svdenoised'
                fieldname='sv';
        end
        if strcmp(echo_obj.echo_usrdata.geometry_y,'depth')
            [x_data_disp,y_data_disp,data,sc]=trans_obj.apply_line_depth(fieldname,idx_r_red,idx_ping_red);
        end
    end
    %y_data_disp=logspace(log10(ydata(idx_r_red(1))),log10(ydata(idx_r_red(end))),numel(idx_r_red));
    
    % x_data_disp=xdata(idx_ping);
    % y_data_disp=ydata(idx_r);
    
    if isempty(data)
        data=nan(size(y_data_disp,1),size(x_data_disp,2));
        sc='lin';
    end
    
    switch sc
        case 'lin'
            data_mat=10*log10(abs(data));
        otherwise
            data_mat=data;
    end
    
    data_mat=single(real(data_mat));
    

    echo_obj.echo_usrdata.Idx_r=idx_r_red;
    echo_obj.echo_usrdata.Idx_pings=idx_ping_red;
    echo_obj.echo_usrdata.CID=trans_obj.Config.ChannelID;
    echo_obj.echo_usrdata.Fieldname=fieldname;
    echo_obj.echo_usrdata.Layer_ID=p.Results.Unique_ID;
    
    switch echo_obj.echo_usrdata.geometry_y
        case 'samples'
            y_data_disp=y_data_disp-1/2;
    end
    
    x_data_disp=x_data_disp-1/2;
    set(echo_h,'XData',x_data_disp,'YData',y_data_disp,'CData',data_mat,'ZData',zeros(size(data_mat)),'AlphaData',ones(size(data_mat)));%,'UserData',data_mat
    
    up=1;
else
    if ~isdeployed()
        disp('Not updating datamat and display');
    end
    x_data_disp=echo_h.XData;
    y_data_disp=echo_h.YData;
    
end

idx_p=echo_obj.echo_usrdata.Idx_pings>=idx_ping_red_ori(1)&echo_obj.echo_usrdata.Idx_pings<=idx_ping_red_ori(end);
idx_r=echo_obj.echo_usrdata.Idx_r>=idx_r_red_ori(1)&echo_obj.echo_usrdata.Idx_r<=idx_r_red_ori(end);


if isempty(p.Results.x)||isempty(p.Results.y)
    echo_obj.main_ax.XLim = [1 numel(trans_obj.Time)];
    echo_obj.main_ax.YLim = [1 numel(trans_obj.Range)];
end

if length(x)>1
    x=x_data_disp(:,idx_p);
    x_lim=[nanmin(x(:)) nanmax(x(:))];
    if x_lim(2)>x_lim(1)&&~any(isinf(x_lim))&&~any(isnan(x_lim))
        echo_obj.echo_usrdata.xlim=x_lim;
    else
        echo_obj.echo_usrdata.xlim=[nan nan];
    end
end

% [y_data_disp(1) y_data_disp(end)]
if length(y_data_disp)>1
    y=y_data_disp(idx_r,:);
    if size(y,2)>1
        y=y(:,idx_p);
    end
    y_lim=[nanmin(y(:)) nanmax(y(:))];
    if y_lim(2)>y_lim(1)&&~any(isinf(y_lim))&&~any(isnan(y_lim))
        echo_obj.echo_usrdata.ylim=y_lim;
    else
        echo_obj.echo_usrdata.ylim=[nan nan];
    end
end

end
%% display_layer.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |layer|: TODO: write description and info on variable
% * |curr_disp|: TODO: write description and info on variable
% * |fieldname|: TODO: write description and info on variable
% * |ax|: TODO: write description and info on variable
% * |echo_h|: TODO: write description and info on variable
% * |x|: TODO: write description and info on variable
% * |y|: TODO: write description and info on variable
% * |new|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |dr|: TODO: write description and info on variable
% * |dp|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [dr,dp,up]=display_layer(layer,curr_disp,fieldname,ax,echo_h,x,y,off_disp,force_update)
up=0;

[trans_obj,idx_t]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end



xdata=trans_obj.get_transceiver_pings();
%xdata=trans_obj.get_dist();
ydata=trans_obj.get_transceiver_samples();

% ydata_r=trans_obj.get_transceiver_range();

% x=x+diff(x)*[-1/2 1/2];
% y=y+diff(y)*[-1/2 1/2];


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
    update_echo=get_update_echo(echo_h,curr_disp.EchoType,layer.Unique_ID,layer.ChannelID{idx_t},fieldname,idx_r_red_ori,idx_ping_red_ori,dr,dp);
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
    if ~strcmpi(echo_h.Type,'image')&&strcmp(ax.UserData.geometry_y,'depth')
        if off_disp>0
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
        y=[nanmin(y_data_disp(:)) nanmax(y_data_disp(:))];
    else
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
        if ~strcmpi(echo_h.Type,'image')&&strcmp(ax.UserData.geometry_y,'depth')
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
    
    usrdata.Idx_r=idx_r_red;
    usrdata.Idx_pings=idx_ping_red;
    usrdata.CID=layer.ChannelID{idx_t};
    usrdata.Fieldname=fieldname;
    usrdata.Layer_ID=layer.Unique_ID;
    
    switch echo_h.Type
        case  'image'
            
            set(echo_h,'XData',x_data_disp,'YData',y_data_disp,'CData',data_mat,'AlphaData',1,'UserData',usrdata);%,'UserData',data_mat
            x_data_disp=x_data_disp-1/2;
        case 'surface'
            switch ax.UserData.geometry_y
                case 'samples'
                    y_data_disp=y_data_disp-1/2;    
            end
            x_data_disp=x_data_disp-1/2;
            set(echo_h,'XData',x_data_disp,'YData',y_data_disp,'CData',data_mat,'ZData',zeros(size(data_mat)),'AlphaData',ones(size(data_mat)),'UserData',usrdata);%,'UserData',data_mat        
    end
    up=1;
else
    if ~isdeployed()
        disp('Not updating datamat and display');
    end
    x_data_disp=echo_h.XData;
    y_data_disp=echo_h.YData;
    switch echo_h.Type
        case  'image'
            x_data_disp=x_data_disp-1/2;
    end
end

idx_p=echo_h.UserData.Idx_pings>=idx_ping_red_ori(1)&echo_h.UserData.Idx_pings<=idx_ping_red_ori(end);
idx_r=echo_h.UserData.Idx_r>=idx_r_red_ori(1)&echo_h.UserData.Idx_r<=idx_r_red_ori(end);


if length(x)>1
    x=x_data_disp(:,idx_p);
    x_lim=[nanmin(x(:)) nanmax(x(:))];
    if x_lim(2)>x_lim(1)&&~any(isinf(x_lim))&&~any(isnan(x_lim))
        ax.UserData.xlim=x_lim;
    else
        ax.UserData.xlim=[nan nan];
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
        ax.UserData.ylim=y_lim;
    else
       ax.UserData.ylim=[nan nan]; 
    end
end

end
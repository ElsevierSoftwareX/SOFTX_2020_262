function [data_struct,no_nav,zone] = get_region_3D_echoes(reg_obj,trans_obj,varargin)

%% input variable management

p = inputParser;

% default values
field_def='sp';

[cax_d,~,~]=init_cax(field_def);
addRequired(p,'reg_obj',@(obj) isa(obj,'region_cl'));
addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl')|isstruct(obj));
addParameter(p,'Name',reg_obj.print(),@ischar);
addParameter(p,'Cax',cax_d,@isnumeric);
addParameter(p,'Cmap','ek60',@ischar);
addParameter(p,'alphadata',[],@isnumeric);
addParameter(p,'field',field_def,@ischar);
addParameter(p,'trackedOnly',0,@isnumeric);
addParameter(p,'comp_angle',1,@isnumeric);
addParameter(p,'comp_att',1,@isnumeric);
addParameter(p,'thr',nan,@isnumeric);
addParameter(p,'main_figure',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'parent',[],@(h) isempty(h)|ishghandle(h));
addParameter(p,'load_bar_comp',[]);

parse(p,reg_obj,trans_obj,varargin{:});

field=p.Results.field;

comp_angle=p.Results.comp_angle;
comp_att=p.Results.comp_angle;

data_struct=[];
no_nav=0;
zone='';

if isempty(reg_obj)
    idx_ping=trans_obj.get_transceiver_pings();
    idx_r=trans_obj.get_transceiver_samples();
else
    idx_ping=reg_obj.Idx_ping;
    idx_r=reg_obj.Idx_r;
end


switch field
    case 'singletarget'
        
        if isempty(trans_obj.ST)
            return;
        end
        idx_keep_p=find(ismember(trans_obj.ST.Ping_number,idx_ping));
        idx_keep_r=find(ismember(trans_obj.ST.idx_r,idx_r));
        idx_keep=intersect(idx_keep_r,idx_keep_p);
        
        if p.Results.trackedOnly==1            
            if isempty(trans_obj.Tracks)
                return;
            end
            idx_keep_ori=idx_keep;
            idx_keep=[];
            for i=1:numel(trans_obj.Tracks.target_id)
                idx_keep=union(idx_keep,intersect(idx_keep_ori,trans_obj.Tracks.target_id{i}));
            end
        end
        
        if isempty(idx_keep)
            warndlg_perso([],'','No single targets');
            return;
        end
        data_disp=trans_obj.ST.TS_comp(idx_keep);
        compensation=zeros(size(data_disp));
        Mask=ones(size(data_disp));
        Range=trans_obj.ST.Target_range(idx_keep);
        AlongAngle=trans_obj.ST.Angle_minor_axis(idx_keep);
        AcrossAngle=trans_obj.ST.Angle_major_axis(idx_keep);
        idx_ping=trans_obj.ST.Ping_number(idx_keep);
        %idx_r=trans_obj.ST.idx_r(idx_keep);
        nb_samples=1;
    otherwise

        switch field
            case 'TS'
                field_load='sp';
            otherwise
                field_load=field;
        end
        nb_samples=length(idx_r);
        nb_pings=length(idx_ping);
        
        Range=repmat(trans_obj.get_transceiver_range(idx_r),1,nb_pings);
        [data_disp,idx_r,idx_ping,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=get_data_from_region(trans_obj,reg_obj,...
            'field',field_load);
        Mask=(~bad_data_mask)&(~below_bot_mask);
        Mask(:,bad_trans_vec)=0;
        
        AlongAngle=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','AlongAngle');
        AcrossAngle=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','AcrossAngle');
        [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
        compensation = simradBeamCompensation(faBW,...
            psBW, AlongAngle, AcrossAngle);
        

end

if ~isempty(trans_obj.GPSDataPing.Lat)
    lat=trans_obj.GPSDataPing.Lat(idx_ping);
    long=trans_obj.GPSDataPing.Long(idx_ping);
    dist=trans_obj.GPSDataPing.Dist(idx_ping);
else
    lat=zeros(size(idx_ping));
    long=zeros(size(idx_ping));
    dist=zeros(size(idx_ping));
end


if nanmean(diff(dist))==0
    warning('No navigation data');
    dist=zeros(size(dist));
    no_nav=1;
    x_geo=zeros(size(dist));
    y_geo=zeros(size(dist));
else
    [x_geo,y_geo,zone]=deg2utm(lat,long);
end

heading_geo=trans_obj.AttitudeNavPing.Heading(idx_ping);%TOFIX when there is no attitude data...
pitch_geo=trans_obj.AttitudeNavPing.Pitch(idx_ping);
roll_geo=trans_obj.AttitudeNavPing.Roll(idx_ping);
heave_geo=trans_obj.AttitudeNavPing.Heave(idx_ping);
yaw_geo=trans_obj.AttitudeNavPing.Yaw(idx_ping);

if isempty(heading_geo)||all(isnan(heading_geo))||all(heading_geo==-999)
    disp('No Heading Data, we''ll pretend to go north');
    heading_geo=zeros(size(idx_ping));
    x_geo=dist;
    y_geo=zeros(size(dist));
end

if isempty(pitch_geo)
    disp('No motion Data, we''ll pretend everythings flat');
    roll_geo=zeros(size(x_geo));
    pitch_geo=zeros(size(x_geo));
    heave_geo=zeros(size(x_geo));
    yaw_geo=zeros(size(x_geo));
end

if size(heading_geo,1)>1
    heading_geo=heading_geo';
end

if size(roll_geo,1)>1
    roll_geo=roll_geo';
    pitch_geo=pitch_geo';
    heave_geo=heave_geo';
    yaw_geo=yaw_geo';
end

if size(x_geo,1)>1
    x_geo=x_geo';
    y_geo=y_geo';
end

pitch_geo(isnan(pitch_geo))=0;
roll_geo(isnan(roll_geo))=0;
heave_geo(isnan(heave_geo))=0;
yaw_geo(isnan(yaw_geo))=0;

pitch=repmat(pitch_geo,nb_samples,1);
roll=repmat(roll_geo,nb_samples,1);
heave=repmat(heave_geo,nb_samples,1);
yaw=repmat(yaw_geo,nb_samples,1);
idx_ping_mat=repmat(idx_ping,nb_samples,1);

X_mat=repmat(x_geo,nb_samples,1);
Y_mat=repmat(y_geo,nb_samples,1);


if comp_angle==0
    AlongAngle=zeros(size(AlongAngle));
    AcrossAngle=zeros(size(AcrossAngle));
end
%AlongAngle=zeros(size(AlongAngle));
%AcrossAngle=zeros(size(AcrossAngle));
%comp_att=0;
if comp_att==0
    heave=zeros(size(heave));
    pitch=zeros(size(heave));
    roll=zeros(size(heave));
    yaw=zeros(size(heave));
end

[Along_dist,Across_dist,Z_t]=arrayfun(@angles_to_pos_single,...
    -Range,...
    AlongAngle,...
    AcrossAngle,...
    heave,...
    pitch,...
    roll,...
    yaw,...
   trans_obj.Config.TransducerAlphaX*ones(size(Range)),....
   trans_obj.Config.TransducerAlphaY*ones(size(Range)),....
   trans_obj.Config.TransducerAlphaZ*ones(size(Range)),....
   trans_obj.Config.TransducerOffsetX*ones(size(Range)),....
   trans_obj.Config.TransducerOffsetY*ones(size(Range)),....
   trans_obj.Config.TransducerOffsetZ*ones(size(Range)));

trans_depth=trans_obj.get_transducer_depth(idx_ping);

Z_t=Z_t-trans_depth;

% 
% X_t=X_mat+Along_dist.*cosd(heading)-Across_dist.*sind(heading);%N/S
% Y_t=Y_mat-Along_dist.*sind(heading)+Across_dist.*cosd(heading);%W/E

X_t=X_mat+Along_dist.*sind(heading_geo)+Across_dist.*cosd(heading_geo);%W/E
Y_t=Y_mat+Along_dist.*cosd(heading_geo)-Across_dist.*sind(heading_geo);%N/S



Bottom_r=trans_obj.get_bottom_depth(idx_ping)-heave_geo;

[Along_dist_bot,Across_dist_bot,Z_bot]=arrayfun(@angles_to_pos_single,...
    -Bottom_r,...
    zeros(size(Bottom_r)),...
    zeros(size(Bottom_r)),...
    heave_geo,...
    pitch_geo,...
    roll_geo,...
    yaw_geo,...
   trans_obj.Config.TransducerAlphaX*ones(size(Bottom_r)),....
   trans_obj.Config.TransducerAlphaY*ones(size(Bottom_r)),....
   trans_obj.Config.TransducerAlphaZ*ones(size(Bottom_r)),....
   trans_obj.Config.TransducerOffsetX*ones(size(Bottom_r)),....
   trans_obj.Config.TransducerOffsetY*ones(size(Bottom_r)),....
   trans_obj.Config.TransducerOffsetZ*ones(size(Bottom_r)));

X_bot=x_geo+Along_dist_bot.*sind(heading_geo)+Across_dist_bot.*cosd(heading_geo);%W/E

Y_bot=y_geo+Along_dist_bot.*cosd(heading_geo)-Across_dist_bot.*sind(heading_geo);%N/S


Surf=heave_geo;

if no_nav==0
    [Lat_t,Lon_t] = utm2degx(X_t(:),Y_t(:),repmat(zone,nb_samples,1));
else
    Lat_t=X_t;
    Lon_t=Y_t;
end

t=trans_obj.get_transceiver_time(idx_ping);

data_struct.data_disp=data_disp(:);
data_struct.mask=Mask(:);
data_struct.compensation=compensation(:);
data_struct.X_t=X_t(:);
data_struct.Y_t=Y_t(:);
data_struct.depth=Z_t(:);
data_struct.x_vessel=x_geo(:);
data_struct.y_vessel=y_geo(:);
data_struct.bottom_x=X_bot(:);
data_struct.bottom_y=Y_bot(:);
data_struct.bottom_z=Z_bot(:);
data_struct.ping_num=idx_ping_mat(:);
data_struct.ping_num_vessel=idx_ping(:);
data_struct.time=t(:);
data_struct.surf=Surf(:);
data_struct.lat=Lat_t(:);
data_struct.lon=Lon_t(:);


% 
% 
% along_pos=repmat(dist',size(Along_dist,1),1)+Along_dist;
% 
% u=figure();
% ax2=axes(u);
% pc=pcolor(ax2,repmat(dist(:)',size(Along_dist,1),1),Range,data_disp);
% mask=Mask&compensation<10&data_disp>-50;
% set(pc,'AlphaData',double(mask),'facealpha','flat','LineStyle','none')
% axis(ax2,'ij');
% hold(ax2,'on');
% 
% plot(ax2,along_pos(mask),Range(mask),'.k','Tag','flare')
% colormap('jet');
% caxis([-50 -20]);
% xlabel('Along Distance(m)');
% ylabel('Depth(m)');grid(ax2,'on');

end
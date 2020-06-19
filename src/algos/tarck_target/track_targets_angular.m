
function output_struct=track_targets_angular(trans_obj,varargin)

%Parse Arguments
p = inputParser;

defaultAlpha=0.7;
checkAlpha=@(alpha)(alpha>=0&&alpha<=1);
defaultBeta=0.5;
checkBeta=@(beta)(beta>=0&&beta<=1);
defaultExcluDistAxis=2;
defaultExcluDistRange=2;
checkExcluDist=@(e)(e>=0&&e<=100);
checkExcluDistAxis=@(e)(e>=0&&e<=100);
defaultMaxStdAxisAngle=2;
checkMaxStdAxisAngle=@(MaxStdAxisAngle)(MaxStdAxisAngle>=0&&MaxStdAxisAngle<=45);
defaultMissedpingExp=5;
checkMissedPingExp=@(e)(e>=0&&e<=100);
defaultWeightAxis=10;
defaultWeightRange=70;
defaultWeightTS=5;
defaultWeightPingGap=5;
checkWeigt=@(w)(w>=0&&w<=100);
default_min_ST_Track=8;
check_min_ST_track=@(st)(st>0&&st<=200);
default_Min_Pings_Track=10;
default_Max_Gap_Track=5;
check_accept=@(st)(st>0&&st<=100);
delta_TS_max=30;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'AlphaMajAxis',defaultAlpha,checkAlpha);
addParameter(p,'AlphaMinAxis',defaultAlpha,checkAlpha);
addParameter(p,'AlphaRange',defaultAlpha,checkAlpha);
addParameter(p,'BetaMajAxis',defaultBeta,checkBeta);
addParameter(p,'BetaMinAxis',defaultBeta,checkBeta);
addParameter(p,'BetaRange',defaultBeta,checkBeta);
addParameter(p,'ExcluDistMajAxis',defaultExcluDistAxis,checkExcluDistAxis);
addParameter(p,'ExcluDistMinAxis',defaultExcluDistAxis,checkExcluDistAxis);
addParameter(p,'ExcluDistRange',defaultExcluDistRange,checkExcluDist);
addParameter(p,'MaxStdMajAxisAngle',defaultMaxStdAxisAngle,checkMaxStdAxisAngle);
addParameter(p,'MaxStdMinAxisAngle',defaultMaxStdAxisAngle,checkMaxStdAxisAngle);
addParameter(p,'MissedPingExpMajAxis',defaultMissedpingExp,checkMissedPingExp);
addParameter(p,'MissedPingExpMinAxis',defaultMissedpingExp,checkMissedPingExp);
addParameter(p,'MissedPingExpRange',defaultMissedpingExp,checkMissedPingExp);
addParameter(p,'WeightMajAxis',defaultWeightAxis,checkWeigt);
addParameter(p,'WeightMinAxis',defaultWeightAxis,checkWeigt);
addParameter(p,'WeightRange',defaultWeightRange,checkWeigt);
addParameter(p,'WeightTS',defaultWeightTS,checkWeigt);
addParameter(p,'WeightPingGap',defaultWeightPingGap,checkWeigt);
addParameter(p,'Min_ST_Track',default_min_ST_Track,check_min_ST_track);
addParameter(p,'Min_Pings_Track',default_Min_Pings_Track,check_accept);
addParameter(p,'Max_Gap_Track',default_Max_Gap_Track,check_accept);
addParameter(p,'IgnoreAttitude',false,@islogical);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);

parse(p,trans_obj,varargin{:});



if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_transceiver_range());
    idx_pings=1:length(trans_obj.get_transceiver_pings());
else
    idx_pings=p.Results.reg_obj.Idx_pings;
    idx_r=p.Results.reg_obj.Idx_r;
end

output_struct.done =  false;
trans_obj.ST.Track_ID = nan(size(trans_obj.ST.TS_comp));
ST=trans_obj.ST;


idx_rem=~((ST.idx_r(:)>=idx_r(1)&ST.idx_r(:)<=idx_r(end))&(ST.Ping_number(:)>=idx_pings(1)&ST.Ping_number(:)<=idx_pings(end)));
i0=find(~idx_rem);

ST = structfun(@(x) x(~idx_rem),ST,'un',0);

nb_targets=length(ST.TS_comp);
if nb_targets==0
    tracks_out.target_id={};
    tracks_out.target_ping_number={};
    tracks_out.id=[];
    output_struct.done =  true;
    output_struct.tracks=tracks_out;
    return;
end

idx_tracks=cell(1,nb_targets);
idx_allocation=zeros(1,nb_targets);
tracks_allocation=nan(1,nb_targets);

%Compute target position in each pings (relative to transducer position+dist)
% X_st = zeros(1,nb_targets);
% Y_st = zeros(1,nb_targets);

%Minor is along Major is Across(Athwart)
if p.Results.IgnoreAttitude==0
    [X_st,Y_st,Z_st]=arrayfun(@angles_to_pos_single,ST.Target_range,...
        ST.Angle_minor_axis,...
        ST.Angle_major_axis,...
        ST.Heave,ST.Pitch,ST.Roll,ST.Yaw,...
        trans_obj.Config.TransducerAlphaX*ones(size(ST.Target_range)),....
        trans_obj.Config.TransducerAlphaY*ones(size(ST.Target_range)),....
        trans_obj.Config.TransducerAlphaZ*ones(size(ST.Target_range)),...
        trans_obj.Config.TransducerOffsetX*ones(size(ST.Target_range)),....
        trans_obj.Config.TransducerOffsetY*ones(size(ST.Target_range)),....
        trans_obj.Config.TransducerOffsetZ*ones(size(ST.Target_range)));
        X_st=-X_st+ST.Dist;
else
    [X_st,Y_st,Z_st]=arrayfun(@angles_to_pos_single,ST.Target_range,ST.Angle_minor_axis,ST.Angle_major_axis,...
        zeros(size(ST.Target_range)),...
        zeros(size(ST.Target_range)),...
        zeros(size(ST.Target_range)),...
         zeros(size(ST.Target_range)),...
        trans_obj.Config.TransducerAlphaX*zeros(size(ST.Target_range)),....
        trans_obj.Config.TransducerAlphaY*zeros(size(ST.Target_range)),....
        trans_obj.Config.TransducerAlphaZ*zeros(size(ST.Target_range)),...
        trans_obj.Config.TransducerOffsetX*zeros(size(ST.Target_range)),....
        trans_obj.Config.TransducerOffsetY*zeros(size(ST.Target_range)),....
        trans_obj.Config.TransducerOffsetZ*zeros(size(ST.Target_range)));
end

Z_st=-Z_st;
R_st=-ST.Target_range;


% figure(2);
% hold on;
% scatter3(X_st+ST.Dist,Z_st,Y_st,8,ST.TS_comp,'filled');
% view(2);
% colormap(jet);
% grid on;
% caxis([-65 -45]);

pings=nanmin(ST.Ping_number):nanmax(ST.Ping_number);
nb_pings=length(pings);
nb_targets_pings=zeros(1,nb_pings);
idx_target=cell(1,nb_pings);
active_tracks=cell(1,nb_pings);


X_o=cell(1,nb_pings);Y_o=cell(1,nb_pings);Z_o=cell(1,nb_pings);R_o=cell(1,nb_pings);
X_p=cell(1,nb_pings);Y_p=cell(1,nb_pings);Z_p=cell(1,nb_pings);R_p=cell(1,nb_pings);
X_s=cell(1,nb_pings);Y_s=cell(1,nb_pings);Z_s=cell(1,nb_pings);R_s=cell(1,nb_pings);

VX_o=cell(1,nb_pings);VY_o=cell(1,nb_pings);VZ_o=cell(1,nb_pings);VR_o=cell(1,nb_pings);
VX_p=cell(1,nb_pings);VY_p=cell(1,nb_pings);VZ_p=cell(1,nb_pings);VR_p=cell(1,nb_pings);
VX_s=cell(1,nb_pings);VY_s=cell(1,nb_pings);VZ_s=cell(1,nb_pings);VR_s=cell(1,nb_pings);

current_ping=pings(1);
idx_target{1}=find(ST.Ping_number==current_ping);
nb_targets_pings(1)=length(idx_target{1});
tracks={};
weight={};
tracks_pings={};
for iip=1:nb_targets_pings(1)
    tracks{iip}=idx_target{1}(iip);
    tracks_pings{iip}=pings(1);
    weight{iip}=0;
    idx_allocation(idx_target{1}(iip))=1;
    tracks_allocation(iip)=idx_target{1}(iip);
end
active_tracks{1}=1:length(tracks);


X_init=X_st(idx_target{1});
Y_init=Y_st(idx_target{1});
Z_init=Z_st(idx_target{1});
R_init=R_st(idx_target{1});

X_o{1}=X_init;Y_o{1}=Y_init;Z_o{1}=Z_init;R_o{1}=R_init;
X_p{1}=X_init;Y_p{1}=Y_init;Z_p{1}=Z_init;R_p{1}=R_init;
X_s{1}=X_init;Y_s{1}=Y_init;Z_s{1}=Z_init;R_s{1}=R_init;

VX_o{1}=zeros(1,nb_targets_pings(1));VY_o{1}=zeros(1,nb_targets_pings(1));VZ_o{1}=zeros(1,nb_targets_pings(1));VR_o{1}=zeros(1,nb_targets_pings(1));
VX_p{1}=zeros(1,nb_targets_pings(1));VY_p{1}=zeros(1,nb_targets_pings(1));VZ_p{1}=zeros(1,nb_targets_pings(1));VR_p{1}=zeros(1,nb_targets_pings(1));
VX_s{1}=zeros(1,nb_targets_pings(1));VY_s{1}=zeros(1,nb_targets_pings(1));VZ_s{1}=zeros(1,nb_targets_pings(1));VR_s{1}=zeros(1,nb_targets_pings(1));

load_bar_comp=p.Results.load_bar_comp;
if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_pings, 'Value',0);
end

for iip=2:nb_pings
    
        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar,'Value',iip);
        end
    
    current_ping=pings(iip);
    idx_target{iip}=find(ST.Ping_number==current_ping&idx_allocation==0);
    nb_targets_pings(iip)=length(idx_target{iip});
    
    X_init=X_st(idx_target{iip});
    Y_init=Y_st(idx_target{iip});
    Z_init=Z_st(idx_target{iip});
    R_init=R_st(idx_target{iip});
    
    X_o{iip}=X_init;Y_o{iip}=Y_init;Z_o{iip}=Z_init;R_o{iip}=R_init;
    X_s{iip}=X_init;Y_s{iip}=Y_init;Z_s{iip}=Z_init;R_s{iip}=R_init;
    
    VX_o{iip}=zeros(1,nb_targets_pings(iip));VY_o{iip}=zeros(1,nb_targets_pings(iip));VZ_o{iip}=zeros(1,nb_targets_pings(iip));VR_o{iip}=zeros(1,nb_targets_pings(iip));
    VX_s{iip}=zeros(1,nb_targets_pings(iip));VY_s{iip}=zeros(1,nb_targets_pings(iip));VZ_s{iip}=zeros(1,nb_targets_pings(iip));VR_s{iip}=zeros(1,nb_targets_pings(iip));
    
    id_prev=iip-1;
    while isempty(X_s{id_prev})&&id_prev>1
        id_prev=id_prev-1;
    end

    if nb_targets_pings(iip)>0&&id_prev>0
        
        X_p{iip}=X_s{id_prev}+VX_s{id_prev}*(pings(iip)-pings(id_prev));
        Y_p{iip}=Y_s{id_prev}+VY_s{id_prev}*(pings(iip)-pings(id_prev));
        Z_p{iip}=Z_s{id_prev}+VZ_s{id_prev}*(pings(iip)-pings(id_prev));
        R_p{iip}=R_s{id_prev}+VR_s{id_prev}*(pings(iip)-pings(id_prev));
        
        %Here we need to define the volume in the new ping in which to find
        %targets from (X_o,Y_o,Z_o,R_o) to match with (X_p,Y_p,Z_p,R_p).
        %Targets from (X_o,Y_o,Z_o,R_o) with no match starts potential new
        %tracks...
        
        u=iip-id_prev-1;
        %         if nansum(VZ_s{i-1})>0
        %             figure(11);
        %             plot(VZ_s{i-1})
        %             pause;
        %         end
        idx_new_target_tot=[];
        while u<=p.Results.Max_Gap_Track&&(iip-1-u)>0
            
            if (nb_targets_pings(iip-u)>0&&~isempty(X_s{iip-1-u}))
                target_gate=...
                    (repmat(Y_o{iip},nb_targets_pings(iip-1-u),1)-repmat(Y_p{iip-u}',1,nb_targets_pings(iip))).^2./((p.Results.ExcluDistMajAxis+repmat(abs(Z_o{iip}),nb_targets_pings(iip-1-u),1)*tand(p.Results.MaxStdMajAxisAngle))*(1+u*p.Results.MissedPingExpMajAxis/100)).^2+...
                    (repmat(X_o{iip},nb_targets_pings(iip-1-u),1)-repmat(X_p{iip-u}',1,nb_targets_pings(iip))).^2./((p.Results.ExcluDistMinAxis+repmat(abs(Z_o{iip}),nb_targets_pings(iip-1-u),1)*tand(p.Results.MaxStdMinAxisAngle))*(1+u*p.Results.MissedPingExpMinAxis/100)).^2+...
                    (repmat(Z_o{iip},nb_targets_pings(iip-1-u),1)-repmat(Z_p{iip-u}',1,nb_targets_pings(iip))).^2/(p.Results.ExcluDistRange*(1+u*p.Results.MissedPingExpRange/100)).^2;
              
%                 target_gate=...
%                     (Y_o{i}-Y_p{i-u}').^2./((p.Results.ExcluDistMajAxis+(abs(Z_o{i}))*tand(p.Results.MaxStdMajAxisAngle))*(1+u*p.Results.MissedPingExpMajAxis/100)).^2+...
%                     (X_o{i}-X_p{i-u}').^2./((p.Results.ExcluDistMinAxis+(abs(Z_o{i}))*tand(p.Results.MaxStdMinAxisAngle))*(1+u*p.Results.MissedPingExpMinAxis/100)).^2+...
%                     (Z_o{i}-Z_p{i-u}').^2/(p.Results.ExcluDistRange*(1+u*p.Results.MissedPingExpRange/100)).^2;
%                              
%                 target_gate=...
%                     bsxfun(@rdivide,bsxfun(@minus,Y_o{i},Y_p{i-u}').^2,(p.Results.ExcluDistMajAxis+(abs(Z_o{i}))*tand(p.Results.MaxStdMajAxisAngle))*(1+u*p.Results.MissedPingExpMajAxis/100)).^2+...
%                     bsxfun(@rdivide,bsxfun(@minus,X_o{i},X_p{i-u}').^2,(p.Results.ExcluDistMinAxis+(abs(Z_o{i}))*tand(p.Results.MaxStdMinAxisAngle))*(1+u*p.Results.MissedPingExpMinAxis/100)).^2+...
%                     bsxfun(@minus,Z_o{i},Z_p{i-u}').^2/(p.Results.ExcluDistRange*(1+u*p.Results.MissedPingExpRange/100)).^2;
%       
                
                
                [idx_old_target,idx_new_target]=find(target_gate<1);
                
                if nb_targets_pings(iip-1-u)>1
                    idx_new_target=idx_new_target';
                end
                jjp=0;
                while jjp<length(idx_new_target)
                    jjp=jjp+1;
                    if nansum(idx_new_target(jjp)==idx_new_target_tot)==0
                        idx_old_track_temp=[];
                        for d=1:length(active_tracks{iip-1-u})
                            if any(tracks{active_tracks{iip-1-u}(d)}==idx_target{iip-u-1}(idx_old_target(jjp)))
                                idx_old_track_temp=unique([idx_old_track_temp active_tracks{iip-1-u}(d)]);
                            end
                        end
                        
                        active_tracks{iip}=([active_tracks{iip} idx_old_track_temp]);
                        for t=1:length(idx_old_track_temp)
                            if ~any(tracks{idx_old_track_temp(t)}==idx_target{iip}(idx_new_target(jjp)))
                                if length(tracks_pings{idx_old_track_temp(t)})>=2
                                    diff_pings=tracks_pings{idx_old_track_temp(t)}(end)-tracks_pings{idx_old_track_temp(t)}(end-1);
                                    diff_TS=(ST.TS_comp(idx_target{iip}(idx_new_target(jjp)))-ST.TS_comp(tracks{idx_old_track_temp(t)}(end-1)));
                                else
                                    diff_pings=0;
                                    diff_TS=0;
                                end
                                
                                curr_weight=p.Results.WeightMajAxis*(Y_o{iip}(idx_new_target(jjp))-Y_p{iip-u}(idx_old_target(jjp))).^2./((p.Results.ExcluDistMajAxis+Z_o{iip}(idx_new_target(jjp))*tand(p.Results.MaxStdMajAxisAngle))*(1+u*p.Results.MissedPingExpMajAxis/100)).^2+...
                                    p.Results.WeightMinAxis*(X_o{iip}(idx_new_target(jjp))-X_p{iip-u}(idx_old_target(jjp))).^2./((p.Results.ExcluDistMinAxis+Z_o{iip}(idx_new_target(jjp))*tand(p.Results.MaxStdMinAxisAngle))*(1+u*p.Results.MissedPingExpMinAxis/100)).^2+...
                                    p.Results.WeightRange*(Z_o{iip}(idx_new_target(jjp))-Z_p{iip-u}(idx_old_target(jjp))).^2/(p.Results.ExcluDistRange*(1+u*p.Results.MissedPingExpRange/100))^2+...
                                    p.Results.WeightTS*diff_TS^2/(delta_TS_max)^2+...
                                    p.Results.WeightPingGap*diff_pings^2/nanmax(p.Results.Max_Gap_Track,1)^2;
                                
                                if idx_allocation(idx_target{iip}(idx_new_target(jjp)))>=1
                                    concurrent_track=tracks_allocation(idx_target{iip}(idx_new_target(jjp)));
                                    track_temp=tracks{concurrent_track};
                                    idx_tar=find(track_temp==idx_new_target(jjp));
                                    temp_weight=weight{concurrent_track}(idx_tar);
                                    tracks_allocation(idx_target{iip}(idx_new_target(jjp)))=idx_old_track_temp(t);
                                    
                                    if curr_weight<temp_weight
                                        tracks{concurrent_track}(idx_tar)=[];
                                        tracks_pings{concurrent_track}(idx_tar)=[];
                                        weight{concurrent_track}(idx_tar)=[];
                                        
                                        tracks_allocation(idx_target{iip}(idx_new_target(jjp)))=idx_old_track_temp(t);
                                        tracks{idx_old_track_temp(t)}=[tracks{idx_old_track_temp(t)} idx_target{iip}(idx_new_target(jjp))];
                                        tracks_pings{idx_old_track_temp(t)}=[tracks_pings{idx_old_track_temp(t)} pings(iip)];
                                        weight{idx_old_track_temp(t)}=[weight{idx_old_track_temp(t)} curr_weight];
                                        
                                        
                                    else
                                        idx_new_target(jjp)=[];
                                        idx_old_target(jjp)=[];
                                        jjp=jjp-1;
                                    end
                                else
                                    idx_allocation(idx_target{iip}(idx_new_target(jjp)))=idx_allocation(idx_target{iip}(idx_new_target(jjp)))+1;
                                    
                                    tracks_allocation(idx_target{iip}(idx_new_target(jjp)))=idx_old_track_temp(t);
                                    tracks{idx_old_track_temp(t)}=[tracks{idx_old_track_temp(t)} idx_target{iip}(idx_new_target(jjp))];
                                    tracks_pings{idx_old_track_temp(t)}=[tracks_pings{idx_old_track_temp(t)} pings(iip)];
                                    weight{idx_old_track_temp(t)}=[weight{idx_old_track_temp(t)} curr_weight];
                                    
                                end
                                
                                
                                
                            end
                        end
                        
                    end
                    
                end
                
                idx_new_target_tot=[idx_new_target_tot idx_new_target()];
                
                if ~isempty(idx_new_target)
                    X_s{iip}(idx_new_target)=X_p{iip-u}(idx_old_target)+p.Results.AlphaMinAxis*(X_o{iip}(idx_new_target)-X_p{iip-u}(idx_old_target));
                    Y_s{iip}(idx_new_target)=Y_p{iip-u}(idx_old_target)+p.Results.AlphaMajAxis*(Y_o{iip}(idx_new_target)-Y_p{iip-u}(idx_old_target));
                    Z_s{iip}(idx_new_target)=Z_p{iip-u}(idx_old_target)+p.Results.AlphaRange*(Z_o{iip}(idx_new_target)-Z_p{iip-u}(idx_old_target));
                    R_s{iip}(idx_new_target)=R_p{iip-u}(idx_old_target)+p.Results.AlphaRange*(R_o{iip}(idx_new_target)-R_p{iip-u}(idx_old_target));
                end
                
                VX_p{iip}=(X_p{iip}-X_s{id_prev})/(pings(iip)-pings(id_prev));
                VY_p{iip}=(Y_p{iip}-Y_s{id_prev})/(pings(iip)-pings(id_prev));
                VZ_p{iip}=(Z_p{iip}-Z_s{id_prev})/(pings(iip)-pings(id_prev));
                VR_p{iip}=(R_p{iip}-R_s{id_prev})/(pings(iip)-pings(id_prev));
                
                if ~isempty(idx_new_target)
                    VX_o{iip}(idx_new_target)=(X_o{iip}(idx_new_target)-X_p{iip-u}(idx_old_target))/(pings(iip)-pings(id_prev));
                    VY_o{iip}(idx_new_target)=(Y_o{iip}(idx_new_target)-Y_p{iip-u}(idx_old_target))/(pings(iip)-pings(id_prev));
                    VZ_o{iip}(idx_new_target)=(Z_o{iip}(idx_new_target)-Z_p{iip-u}(idx_old_target))/(pings(iip)-pings(id_prev));
                    VR_o{iip}(idx_new_target)=(R_o{iip}(idx_new_target)-R_p{iip-u}(idx_old_target));
                    
                    VX_s{iip}(idx_new_target)=VX_p{iip-u}(idx_old_target)+p.Results.BetaMinAxis*(VX_o{iip}(idx_new_target)-VX_p{iip-u}(idx_old_target));
                    VY_s{iip}(idx_new_target)=VY_p{iip-u}(idx_old_target)+p.Results.BetaMajAxis*(VY_o{iip}(idx_new_target)-VY_p{iip-u}(idx_old_target));
                    VZ_s{iip}(idx_new_target)=VZ_p{iip-u}(idx_old_target)+p.Results.BetaRange*(VZ_o{iip}(idx_new_target)-VZ_p{iip-u}(idx_old_target));
                    VR_s{iip}(idx_new_target)=VR_p{iip-u}(idx_old_target)+p.Results.BetaRange*(VR_o{iip}(idx_new_target)-VR_p{iip-u}(idx_old_target));
                end
            end
            u=u+1;
        end
        
        
        idx_new_tracks=(1:nb_targets_pings(iip));
        idx_new_tracks(idx_new_target_tot)=[];
        
        
        for k=1:length(idx_new_tracks)
            tracks{length(tracks)+1}=idx_target{iip}(idx_new_tracks(k));
            tracks_pings{length(tracks_pings)+1}=current_ping;
            weight{length(weight)+1}=0;
            active_tracks{iip}=[active_tracks{iip} length(tracks)];
            idx_allocation(idx_target{iip}(idx_new_tracks(k)))=1;
            idx_tracks{idx_target{iip}(idx_new_tracks(k))}=length(tracks);
            tracks_allocation(idx_target{iip}(idx_new_tracks(k)))=length(tracks);
        end
    else
        
        X_p{iip}=X_init;Y_p{iip}=Y_init;Z_p{iip}=Z_init;R_p{iip}=R_init;
        VX_p{iip}=zeros(1,nb_targets_pings(iip));
        VY_p{iip}=zeros(1,nb_targets_pings(iip));
        VZ_p{iip}=zeros(1,nb_targets_pings(iip));
        VR_p{iip}=zeros(1,nb_targets_pings(iip));
        
        if nb_targets_pings(iip)>0
            idx_new_tracks=(1:nb_targets_pings(iip));
            for k=1:length(idx_new_tracks)
                tracks{length(tracks)+1}=idx_target{iip}(idx_new_tracks(k));
                tracks_pings{length(tracks_pings)+1}=current_ping;
                weight{length(weight)+1}=0;
                active_tracks{iip}=[active_tracks{iip} length(tracks)];
                idx_allocation(idx_target{iip}(idx_new_tracks(k)))=1;
                tracks_allocation=length(tracks);
            end
        end
    end
    %         figure(12);
    %         clf
    %         scatter3(X_o{i},Y_o{i},Z_o{i},40,'fill')
    %         hold on;
    %         scatter3(X_s{i},Y_s{i},Z_s{i},40,'fill','g')
    %         scatter3(X_p{i},Y_p{i},Z_p{i},40,'fill','r')
    %
    %     view(2)
    % drawnow;
    %
    
end


tracks_out.target_id={};
tracks_out.uid={};
tracks_out.target_ping_number={};

for iip=1:length(tracks)
    
    idx_targets=tracks{iip};
    
    if length(idx_targets)>=p.Results.Min_ST_Track&&(nanmax(ST.Ping_number(idx_targets)-nanmin(ST.Ping_number(idx_targets))+1))>=p.Results.Min_Pings_Track
        unique_pings=unique(tracks_pings{iip});
        
        for t=1:length(unique_pings)
            idx_target_same_ping=find(tracks_pings{iip}==unique_pings(t));
            min_weight=nanmin(weight{iip}(idx_target_same_ping));
            idx_remove=idx_target_same_ping(weight{iip}(idx_target_same_ping)>min_weight);
            tracks_pings{iip}(idx_remove)=[];
            weight{iip}(idx_remove)=[];
            tracks{iip}(idx_remove)=[];
            idx_targets(idx_remove)=[];
        end
        %idx_good_tracks=[idx_good_tracks i];
        
        tracks_out.target_id{length(tracks_out.target_id)+1}=i0(tracks{iip});
        tracks_out.target_ping_number{length(tracks_out.target_ping_number)+1}=tracks_pings{iip};
    else
        tracks{iip}=[];
        tracks_pings{iip}=[];
        weight{iip}=[];
    end
end

tracks_out.id=1:numel(tracks_out.target_ping_number);
tracks_out.uid=generate_Unique_ID(numel(tracks_out.target_ping_number));
output_struct.tracks=tracks_out;
output_struct.done = true;
trans_obj.Tracks=output_struct.tracks;

for k=1:length(trans_obj.Tracks.target_id)
    idx_targets=trans_obj.Tracks.target_id{k};
    trans_obj.ST.Track_ID(idx_targets)=k;
end

            
end
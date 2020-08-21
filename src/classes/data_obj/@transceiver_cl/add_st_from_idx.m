function  add_st_from_idx(trans_obj,idx_r,idx_p)

range_t=trans_obj.get_transceiver_range();
time_t=trans_obj.get_transceiver_time();
idx_r=idx_r(:)';
idx_p=idx_p(:)';
single_targets=init_st_struct();
idx_targets_lin=idx_r+(idx_p-1)*numel(range_t);

[BW_along,BW_athwart] = trans_obj.get_beamwidth_at_f_c([]);

[T,Np_t]=trans_obj.get_pulse_Teff(idx_p);

dt=trans_obj.get_params_value('SampleInterval',idx_ping(1));
dr=dt*nanmean(trans_obj.get_soundspeed(idx_r))/2;

single_targets.Target_range=range_t(idx_r);
single_targets.idx_r= idx_r;
single_targets.Target_range_min=range_t(idx_r)'-Np_t/2*dr;
single_targets.Target_range_max=range_t(idx_r)'-Np_t/2*dr;
single_targets.StandDev_Angles_Minor_Axis=zeros(size(idx_r));
single_targets.StandDev_Angles_Major_Axis=zeros(size(idx_r));
single_targets.Angle_minor_axis=zeros(size(idx_p));
single_targets.Angle_major_axis=zeros(size(idx_p));
single_targets.TS_uncomp=zeros(size(idx_p));
single_targets.TS_comp=zeros(size(idx_p));

for ip=1:numel(idx_p)
    single_targets.Angle_minor_axis(ip)=trans_obj.Data.get_subdatamat('idx_r',idx_r(ip),'idx_ping',idx_p(ip),'field','AlongAngle');
    single_targets.Angle_major_axis(ip)=trans_obj.Data.get_subdatamat('idx_r',idx_r(ip),'idx_ping',idx_p(ip),'field','AcrossAngle');
    single_targets.TS_uncomp(ip)=trans_obj.Data.get_subdatamat('idx_r',idx_r(ip),'idx_ping',idx_p(ip),'field','sp');
    simradBeamComp = simradBeamCompensation(BW_along, BW_athwart, single_targets.Angle_minor_axis(ip), single_targets.Angle_major_axis(ip));
    single_targets.TS_comp(ip)=single_targets.TS_uncomp(ip)+simradBeamComp;
end

single_targets.Ping_number=idx_p;
single_targets.Time=time_t(idx_p);
single_targets.idx_target_lin=idx_targets_lin;
single_targets.pulse_env_before_lin=Np_t/2*dt;
single_targets.pulse_env_after_lin=Np_t/2*dt;
single_targets.Transmitted_pulse_length=T;
single_targets.PulseLength_Normalized_PLDL=T./T;

heading=trans_obj.AttitudeNavPing.Heading(:)';
pitch=trans_obj.AttitudeNavPing.Pitch(:)';
roll=trans_obj.AttitudeNavPing.Roll(:)';
heave=trans_obj.AttitudeNavPing.Heave(:)';
yaw=trans_obj.AttitudeNavPing.Yaw(:)';
dist=trans_obj.GPSDataPing.Dist(:)';

pitch(isnan(pitch))=0;

roll(isnan(roll))=0;

heave(isnan(heave))=0;

dist(isnan(dist))= 0;


if isempty(dist)
    dist=zeros(1,nb_pings_tot);
end

if isempty(heading)||all(isnan(heading))||all(heading==-999)
    heading=zeros(1,nb_pings_tot);
end

if isempty(roll)
    roll=zeros(1,nb_pings_tot);
    pitch=zeros(1,nb_pings_tot);
    heave=zeros(1,nb_pings_tot);
end


single_targets.Dist=dist(single_targets.Ping_number);
single_targets.Roll=roll(single_targets.Ping_number);
single_targets.Pitch=pitch(single_targets.Ping_number);
single_targets.Yaw=yaw(single_targets.Ping_number);
single_targets.Heave=heave(single_targets.Ping_number);
single_targets.Heading=heading(single_targets.Ping_number);

fields_st=fieldnames(single_targets);
for ifi=1:numel(fields_st)
    single_targets.(fields_st{ifi})=single_targets.(fields_st{ifi})(:)';
end
single_targets_tot=trans_obj.ST;
[~,idx_keep]=setdiff(single_targets.idx_target_lin,single_targets_tot.idx_target_lin);
if ~isempty( single_targets_tot.idx_target_lin)
    for ifi=1:numel(fields_st)
        if numel(single_targets.(fields_st{ifi}))==numel(single_targets.Ping_number)
            single_targets_tot.(fields_st{ifi})=cat(2,single_targets_tot.(fields_st{ifi}),single_targets.(fields_st{ifi})(idx_keep));
        end
    end
else
    single_targets_tot=single_targets;
end

trans_obj.set_ST(single_targets_tot);


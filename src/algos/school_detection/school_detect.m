%% school_detect.m
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
% * |trans_obj|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |linked_candidates|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output_struct = school_detect(trans_obj,varargin)

p = inputParser;

check_trans_class=@(obj) isa(obj,'transceiver_cl');

default_thr_sv=-70;
check_thr_sv=@(thr)(thr>=-999&&thr<=0);

default_thr_sv_max=Inf;
check_thr_sv_max=@(thr)(thr>=-999&&thr<=Inf);

default_l_min_can=15;
check_l_min_can=@(l)(l>=0&&l<=500);

default_h_min_can=5;
check_h_min_can=@(l)(l>=0&&l<=100);

default_l_min_tot=25;
check_l_min_tot=@(l)(l>=0);

default_h_min_tot=10;
check_h_min_tot=@(l)(l>=0);

default_horz_link_max=55;
check_horz_link_max=@(l)(l>=0&&l<=1000);

default_vert_link_max=5;
check_vert_link_max=@(l)(l>=0&&l<=500);

default_nb_min_sples=100;
check_nb_min_sples=@(l)(l>0);


addRequired(p,'trans_obj',check_trans_class);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'thr_sv',default_thr_sv,check_thr_sv);
addParameter(p,'thr_sv_max',default_thr_sv_max,check_thr_sv_max);
addParameter(p,'l_min_can',default_l_min_can,check_l_min_can);
addParameter(p,'h_min_can',default_h_min_can,check_h_min_can);
addParameter(p,'l_min_tot',default_l_min_tot,check_l_min_tot);
addParameter(p,'h_min_tot',default_h_min_tot,check_h_min_tot);
addParameter(p,'horz_link_max',default_horz_link_max,check_horz_link_max);
addParameter(p,'vert_link_max',default_vert_link_max,check_vert_link_max);
addParameter(p,'nb_min_sples',default_nb_min_sples,check_nb_min_sples);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);

parse(p,trans_obj,varargin{:});

output_struct.linked_candidate=[];
output_struct.done =  false;

[~,Np_p]=trans_obj.get_pulse_length();

if isempty(p.Results.reg_obj)
    idx_r=(1:length(trans_obj.get_transceiver_range()))';
    idx_pings=1:length(trans_obj.get_transceiver_pings());
    idx_r(idx_r<3*nanmax(Np_p))=[];
    reg_obj=region_cl('Idx_r',idx_r,'Idx_pings',idx_pings);
else
    reg_obj=p.Results.reg_obj;
    idx_r=reg_obj.Idx_r;
end

if p.Results.denoised
    field='svdenoised';
else
    field = 'sv';
end

if ~ismember(field,trans_obj.Data.Fieldname)
    field='sv';
end


range_tot = trans_obj.get_transceiver_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r)
    disp_perso([],'Nothing to detect school from...');
    return;
end

reg_schools=trans_obj.get_region_from_name('School');

for i=1:length(reg_schools)
    mask_inter=reg_obj.get_mask_from_intersection(reg_schools(i));
    if any(mask_inter(:))
        %id_rem=union(id_rem,reg_schools(i).Unique_ID);
        trans_obj.rm_region_id(reg_schools(i).Unique_ID);
    end
end

[Sv_mat,idx_r,idx_pings,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=get_data_from_region(trans_obj,reg_obj,'field',field);

Sv_mat(:,bad_trans_vec)=nan;
Sv_mat(bad_data_mask|below_bot_mask)=nan;


range=trans_obj.get_transceiver_range(idx_r);
dist=trans_obj.GPSDataPing.Dist;

if nanmean(diff(dist))>0
    dist_pings=dist(idx_pings);
else
    warning('No Distance was computed, using ping instead of distance for school detection');
    dist_pings=trans_obj.get_transceiver_pings(idx_pings)';
end

[~,Np]=trans_obj.get_pulse_Teff(idx_pings);
thr_sv=p.Results.thr_sv;
thr_sv_max=p.Results.thr_sv_max;
l_min_can=p.Results.l_min_can;
h_min_can=p.Results.h_min_can;
l_min_tot=p.Results.l_min_tot;
h_min_tot=p.Results.h_min_tot;
horz_link_max=p.Results.horz_link_max;
vert_link_max=p.Results.vert_link_max;
nb_min_sples=p.Results.nb_min_sples;
%

idx_rem=(idx_r<3*nanmax(Np_p));

Sv_mask_ori=(Sv_mat>=thr_sv)&(Sv_mat<=thr_sv_max);

Sv_mask_ori(range>=p.Results.r_max|range<=p.Results.r_min,:)=0;
Sv_mask=filter2(ones(3*ceil(nanmean(Np)),1),Sv_mask_ori,'same')>1;
Sv_mask(idx_rem(:),:)=false;
% 

candidates=find_candidates_v3(Sv_mask,range,dist_pings,l_min_can,h_min_can,nb_min_sples,'mat',p.Results.load_bar_comp);

linked_candidates_mini=link_candidates_v2(candidates,dist_pings,range,horz_link_max,vert_link_max,l_min_tot,h_min_tot,p.Results.load_bar_comp);

output_struct.linked_candidates=sparse(linked_candidates_mini);

dd=nanmax(diff(trans_obj.GPSDataPing.Dist(idx_pings)));

dr=nanmax(diff(trans_obj.get_transceiver_range(idx_r)));

if dd>0
    w_unit='meters';
    cell_w=nanmax(l_min_can/2,2*dd);
else
    w_unit='pings';
    cell_w=round(nanmax(l_min_can/2,2*dd));
end

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Creating regions');
end

trans_obj.create_regions_from_linked_candidates(output_struct.linked_candidates,'w_unit',w_unit,'h_unit','meters','idx_r',idx_r,'idx_pings',idx_pings,...
    'cell_w',cell_w,'cell_h',nanmax(dr*2,h_min_can/10),'reg_names','School');

output_struct.done =  true;

end
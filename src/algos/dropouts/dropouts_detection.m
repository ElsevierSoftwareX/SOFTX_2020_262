function output_struct=dropouts_detection(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));

addParameter(p,'thr_sv',-70,@isnumeric);
addParameter(p,'thr_sv_max',-35,@isnumeric);
addParameter(p,'gate_dB',3,@isnumeric);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

output_struct.done = false;

if isempty(p.Results.reg_obj)
    idx_r=1:length(trans_obj.get_transceiver_range());
    idx_pings_tot=1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Temp','Idx_r',idx_r,'Idx_pings',idx_pings_tot);
    
else
    reg_obj=p.Results.reg_obj;
    idx_pings_tot=p.Results.reg_obj.Idx_pings;
    idx_r=p.Results.reg_obj.Idx_r;
end

range_tot = trans_obj.get_transceiver_range(idx_r);

if ~isempty(idx_r)
    idx_r(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

idx_noise_sector=false(1,numel(idx_pings_tot));

if isempty(idx_r)
    output_struct.idx_noise_sector=idx_noise_sector;
    return;
end


block_size=nanmin(ceil(p.Results.block_len/numel(idx_r)),numel(idx_pings_tot));
num_ite=ceil(numel(idx_pings_tot)/block_size);
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end


block_size=nanmin(ceil(p.Results.block_len/numel(idx_r)),numel(idx_pings_tot));
num_ite=ceil(numel(idx_pings_tot)/block_size);
if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end


load_bar_comp=p.Results.load_bar_comp;
if ~isempty(p.Results.load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end

idx_noise_sector=[];
for ui=1:num_ite
    idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_pings',idx_pings);
    
    [Sv,idx_r,idx_pings,bad_data_mask,bad_trans_vec,inter_mask,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,'field','sv',...
        'intersect_only',1,...
        'regs',reg_obj);
    Sv(below_bot_mask|isinf(Sv))=nan;
    Sv(:,bad_trans_vec)=nan;
    Sv_mean_db=nanmean(Sv);
    Sv_mean_db_tot=nanmean(Sv_mean_db);
    
    idx_tmp=idx_pings(((Sv_mean_db<p.Results.thr_sv)&abs(Sv_mean_db-Sv_mean_db_tot)>p.Results.gate_dB));
    idx_noise_sector=union(idx_tmp,idx_noise_sector);
end
output_struct.idx_noise_sector=idx_noise_sector;
output_struct.done = true;

tag = trans_obj.Bottom.Tag;
if isempty(p.Results.reg_obj)
    tag = ones(size(tag));
else
    tag = trans_obj.Bottom.Tag;
end
tag(output_struct.idx_noise_sector) = 0;

trans_obj.Bottom.Tag = tag;



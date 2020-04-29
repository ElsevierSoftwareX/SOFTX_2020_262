function ouptut_struct=spike_removal(trans_obj,varargin)


p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));

addParameter(p,'r_min',0,@isnumeric);
addParameter(p,'r_max',Inf,@isnumeric);
addParameter(p,'thr_spikes',10,@isnumeric);
addParameter(p,'thr_sp',-80,@isnumeric);
addParameter(p,'v_filt',1.5,@isnumeric);
addParameter(p,'denoised',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'flag_bad_pings',100,@isnumeric)
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});
nb_spikes=0;
if isempty(p.Results.reg_obj)
    idx_r_tot=1:length(trans_obj.get_transceiver_range());
    idx_pings_tot=1:length(trans_obj.get_transceiver_pings());
else
    idx_pings_tot=p.Results.reg_obj.Idx_pings;
    idx_r_tot=p.Results.reg_obj.Idx_r;
end
ouptut_struct.done=false;
idx_bot=trans_obj.get_bottom_idx();
 

range_tot=trans_obj.get_transceiver_range(idx_r_tot);

if ~isempty(idx_r_tot)
    idx_r_tot(range_tot<p.Results.r_min|range_tot>p.Results.r_max)=[];
end

if isempty(idx_r_tot)
    disp_perso([],'Nothing to remove spikes from...');
    return; 
end

range_tot=trans_obj.get_transceiver_range(idx_r_tot);



Np=floor(p.Results.v_filt/nanmean(diff(range_tot)));

block_size=nanmin(ceil(p.Results.block_len/numel(idx_r_tot)),numel(idx_pings_tot));
num_ite=ceil(numel(idx_pings_tot)/block_size);

load_bar_comp=p.Results.load_bar_comp;
if ~isempty(p.Results.load_bar_comp)
    load_bar_comp.progress_bar.setText('Spikes removal');
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
tag=trans_obj.Bottom.Tag;
for ui=1:num_ite
    idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
    
    if p.Results.denoised==1
        sv_spikes=trans_obj.Data.get_subdatamat(idx_r_tot,idx_pings,'field','spdenoised');
        if isempty(sv_spikes)
            sv_spikes=trans_obj.Data.get_subdatamat(idx_r_tot,idx_pings,'field','sp');
        end
    else
        sv_spikes=trans_obj.Data.get_subdatamat(idx_r_tot,idx_pings,'field','sp');
    end
    
    below_bot=idx_r_tot(:)>idx_bot(idx_pings);
    sv_spikes(below_bot)=-999;
    
    sv_filtered=pow2db_perso(filter2_perso(ones(2*Np,1),db2pow(sv_spikes)));
    
    Fx=nan(size(sv_filtered));
    [~,nb_pings]=size(sv_filtered);
    Fx(:,1:nb_pings-1)=-(sv_filtered(:,2:nb_pings)-sv_filtered(:,1:nb_pings-1));
    Fx(:,2:nb_pings)=nanmin(Fx(:,2:nb_pings),(sv_filtered(:,2:nb_pings)-sv_filtered(:,1:nb_pings-1)));
    
    Fx2=nan(size(sv_filtered));
    Fx2(:,1:nb_pings-2)=-(sv_filtered(:,3:nb_pings)-sv_filtered(:,1:nb_pings-2));
    Fx2(:,3:nb_pings)=nanmin(Fx2(:,3:nb_pings),(sv_filtered(:,3:nb_pings)-sv_filtered(:,1:nb_pings-2)));
    
    mask=Fx>p.Results.thr_spikes&sv_spikes>p.Results.thr_sp|Fx2>p.Results.thr_spikes&sv_spikes>p.Results.thr_sp;

    mask=floor(filter2_perso(ones(Np,1),mask))==1;
    mask=ceil(filter2_perso(ones(2*Np,1),mask))==1;
    nb_spikes=nb_spikes+nansum(mask(:));
    
% 
%     sv_spikes_ori=sv_spikes;
%     sv_spikes(mask)=-Inf;
%     
%     figure();
%     ax1=subplot(1,3,1);
%     imagesc(sv_spikes_ori,'alphadata',double(sv_spikes_ori>p.Results.thr_sp))
%     caxis([p.Results.thr_sp p.Results.thr_sp+35]);
%     
%     ax=subplot(1,3,2);
%     imagesc(ax,Fx,'alphadata',mask);
%     
%     ax2=subplot(1,3,3);
%     imagesc(sv_spikes,'alphadata',double(sv_spikes>p.Results.thr_sp))
%     caxis([p.Results.thr_sp p.Results.thr_sp+35]);
%     linkaxes([ax1 ax2 ax ],'xy');
     

    trans_obj.Data.replace_sub_data_v2('spikesmask',mask,idx_r_tot,idx_pings);
%     
    if p.Results.flag_bad_pings<100
        
        tag(idx_pings(nansum(mask)./nansum(below_bot==0)*100>p.Results.flag_bad_pings))=0;
        

        trans_obj.Bottom.Tag = tag;

    end
    
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
   
end
nb_samples=numel(idx_r_tot)*numel(idx_pings_tot);
fprintf('%d samples removed from %d\n',nb_spikes,nb_samples); 
ouptut_struct.done=true;
if ~isempty(p.Results.load_bar_comp)
    load_bar_comp.progress_bar.setText('');
end
end
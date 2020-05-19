function multi_freq_slice_transect2D(layer_obj,varargin)
p = inputParser;

addRequired(p,'layer_obj',@(layer_obj) isa(layer_obj,'layer_cl'));
addParameter(p,'idx_main_freq',1,@isnumeric);
addParameter(p,'idx_sec_freq',[],@isnumeric);
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'survey_options',survey_options_cl,@(x) isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'keep_all',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'tag_sliced_output',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,layer_obj,varargin{:});

if isempty(p.Results.block_len)
    block_len=get_block_len(100,'cpu');
else
    block_len= p.Results.block_len;
end

surv_opt_obj=p.Results.survey_options;

regions_init=[p.Results.regs layer_obj.Transceivers(p.Results.idx_main_freq).Regions(p.Results.idx_regs)];

regs_out=cell(1,numel(regions_init));
idx_freq_out=cell(numel(regions_init),1);
r_factor=cell(1,numel(regions_init));
t_factor=cell(1,numel(regions_init));

for i=1:numel(regions_init)
    [regs_end,idx_freq_end,r_fac,t_fac]=layer_obj.generate_regions_for_other_freqs(p.Results.idx_main_freq,regions_init(i),p.Results.idx_sec_freq);
    regs=[regions_init(i) regs_end];
    r_fac=[1 r_fac];
    t_fac=[1 t_fac];
    [idx_freq_out{i},is]=sort([p.Results.idx_main_freq,idx_freq_end]);
    regs_out{i}=regs(is);
    r_factor{i}=r_fac(is);
    t_factor{i}=t_fac(is);
end

idx_freq_out_tot=unique([idx_freq_out{:}]);

if isempty(idx_freq_out_tot)
    idx_freq_out_tot=union(p.Results.idx_main_freq,p.Results.idx_sec_freq);
end

output_2D=cell(1,numel(idx_freq_out_tot));
out_type=cell(1,numel(idx_freq_out_tot));
regCellInt=cell(1,numel(idx_freq_out_tot));
shadow_height_est=cell(1,numel(idx_freq_out_tot));
regs=cell(1,numel(idx_freq_out_tot));
t_main=layer_obj.Transceivers(p.Results.idx_main_freq).get_transceiver_time();
dt_main=nanmean(diff(t_main));

for i_freq=1:numel(idx_freq_out_tot)
    
    idx_regs=cellfun(@(x) x==idx_freq_out_tot(i_freq) ,idx_freq_out,'un',0);
    regs_temp=[];
    t_fac=[];
    %r_fac=[];
    for ireg=1:numel(idx_regs)
        regs_temp=[regs_temp regs_out{ireg}(idx_regs{ireg})];
        t_fac=[t_fac t_factor{ireg}(idx_regs{ireg})];
        %r_fac=[r_fac r_factor{ireg}(idx_regs{ireg})];
    end
    
    t_new=layer_obj.Transceivers(idx_freq_out_tot(i_freq)).get_transceiver_time();
    dt_new=nanmean(diff(t_new));
    
    switch surv_opt_obj.Vertical_slice_units
        case 'pings'
            surv_opt_obj.Vertical_slice_size=floor(p.Results.survey_options.Vertical_slice_size* dt_main/dt_new);
        case {'meters' 'seconds'}
            surv_opt_obj.Vertical_slice_size=p.Results.survey_options.Vertical_slice_size;
    end
    
    %surv_opt_obj.Vertical_slice_size=floor(surv_opt_obj.Vertical_slice_size*nanmean(t_fac));
    
    trans_obj=layer_obj.Transceivers(idx_freq_out_tot(i_freq));
    [output_2D{i_freq},out_type{i_freq},regs{i_freq},regCellInt{i_freq},shadow_height_est{i_freq}]=trans_obj.slice_transect2D_new_int(...
        'timeBounds',p.Results.timeBounds,...
        'regs',regs_temp,....
        'idx_regs',[],...
        'survey_options',surv_opt_obj,...
        'load_bar_comp',p.Results.load_bar_comp,...
        'block_len',block_len,...
        'tag_sliced_output',p.Results.tag_sliced_output,...
        'keep_all',p.Results.keep_all,...
        'keep_bottom',p.Results.keep_bottom);
end

idx_main_freq=p.Results.idx_main_freq;
reg_descr_table=[];

idx_main=p.Results.idx_main_freq==idx_freq_out_tot;


for ireg=1:length(regs{idx_main})
    reg_descriptors=layer_obj.Transceivers(p.Results.idx_main_freq).get_region_descriptors(regs{idx_freq_out_tot==idx_main_freq}{ireg},'survey_data',layer_obj.get_survey_data());
    for ir=1:length(idx_freq_out_tot)
        output_reg=regCellInt{ir}{ireg};
        if ~isempty(output_reg)
            if istall(output_reg.sv_mean)
                sv_mean=gather(output_reg.sv_mean);
            else
                sv_mean=output_reg.sv_mean;
            end
            sv_mean(sv_mean==0)=nan;
            Sv_mean=pow2db_perso(nanmean(sv_mean(:)));
            delta_sv=nanstd(pow2db_perso(sv_mean(:)));
            reg_descriptors.(sprintf('Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_out_tot(ir))/1e3))=Sv_mean;
            reg_descriptors.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_out_tot(ir))/1e3))=delta_sv;
        else
            reg_descriptors.(sprintf('Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_out_tot(ir))/1e3))=nan;
            reg_descriptors.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_out_tot(ir))/1e3))=nan;
        end
    end
    reg_descr_table = [reg_descr_table;struct2table(reg_descriptors,'asarray',1)];
end


idx_freq_other=setdiff(idx_freq_out_tot,p.Results.idx_main_freq);

for ir=1:length(idx_freq_other)
    idx_sec=idx_freq_other(ir)==idx_freq_out_tot;
    
    for ity=1:numel(output_2D{idx_main})
        if ~isempty(output_2D{idx_main}{ity})
            
            
            ity_sec=strcmpi(out_type{idx_sec},out_type{idx_main}{ity});
            if any(ity_sec)
                if ~istall(output_2D{idx_main}{ity}.eint)
                    data_size=size(output_2D{idx_main}{ity}.eint);
                    sv_mean=output_2D{idx_sec}{ity_sec}.sv_mean;
                    sd_Sv = output_2D{idx_sec}{ity_sec}.sd_Sv;
                    PRC = output_2D{idx_sec}{ity_sec}.PRC;
                    ABC = output_2D{idx_sec}{ity_sec}.ABC;
                else
                    data_size=gather(size(output_2D{idx_main}{ity}.eint));
                    sv_mean=gather(output_2D{idx_sec}{ity_sec}.sv_mean);
                    sd_Sv = gather(output_2D{idx_sec}{ity_sec}.sd_Sv);
                    PRC = gather(output_2D{idx_sec}{ity_sec}.PRC);
                    ABC = gather(output_2D{idx_sec}{ity_sec}.ABC);
                end
                
                output_2D{idx_main}{ity}.(sprintf('sv_mean_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=zeros(data_size);
                output_2D{idx_main}{ity}.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=zeros(data_size);
                output_2D{idx_main}{ity}.(sprintf('PRC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=zeros(data_size);
                output_2D{idx_main}{ity}.(sprintf('ABC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=zeros(data_size);             
                
                
                
                [mask_in,mask_out] = match_data(gather(output_2D{idx_sec}{ity}.Time_S),output_2D{idx_sec}{ity_sec}.Range_ref_min,output_2D{idx_main}{ity}.Time_S,output_2D{idx_main}{ity}.Range_ref_min);
                output_2D{idx_main}{ity}.(sprintf('sv_mean_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))(mask_out)=sv_mean(mask_in);
                output_2D{idx_main}{ity}.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))(mask_out)=sd_Sv(mask_in);
                output_2D{idx_main}{ity}.(sprintf('PRC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))(mask_out)=PRC(mask_in);
                output_2D{idx_main}{ity}.(sprintf('ABC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))(mask_out)=ABC(mask_in);
                if istall(output_2D{idx_main}{ity}.eint)
                    output_2D{idx_main}{ity}.(sprintf('sv_mean_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=tall(output_2D{idx_main}{ity}.(sprintf('sv_mean_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3)));
                    output_2D{idx_main}{ity}.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=tall(output_2D{idx_main}{ity}.(sprintf('sd_Sv_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3)));
                    output_2D{idx_main}{ity}.(sprintf('PRC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=tall(output_2D{idx_main}{ity}.(sprintf('PRC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3)));
                    output_2D{idx_main}{ity}.(sprintf('ABC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3))=tall(output_2D{idx_main}{ity}.(sprintf('ABC_%.0fkHz',layer_obj.Frequencies(idx_freq_other(ir))/1e3)));
                end
            end
            %figure();imagesc(pow2db_perso(output_2D_surf_sec.sv_mean));
        end
    end
    
end

layer_obj.EchoIntStruct.output_2D=output_2D;
layer_obj.EchoIntStruct.output_2D_type=out_type;
layer_obj.EchoIntStruct.regs_tot=regs;
layer_obj.EchoIntStruct.regCellInt_tot=regCellInt;
layer_obj.EchoIntStruct.reg_descr_table=reg_descr_table;
layer_obj.EchoIntStruct.shz_height_est=shadow_height_est;
layer_obj.EchoIntStruct.idx_freq_out=idx_freq_out_tot;
layer_obj.EchoIntStruct.survey_options=p.Results.survey_options;

end

function [mask_in,mask_out]=match_data(t_in,r_in,t_out,r_out)

if istall(t_in)
    t_in = gather(t_in);
end

if istall(r_in)
    r_in = gather(r_in);
end

if istall(t_out)
    t_out = gather(t_out);
end

if istall(r_out)
    r_out = gather(r_out);
end


mask_in=zeros(size(r_in,1),size(t_in,2));
mask_out=zeros(size(r_out,1),size(t_out,2));
dt=gradient(t_out);

if size(r_out,2)==1
    dr = gradient(r_out);
elseif size(r_out,1)==1
    dr=inf;
else
    [~,dr] = gradient(r_out);
end

for j=1:size(t_out,2)
    [~,idx_t]=nanmin(abs(t_out(j)-t_in));
    if abs(t_in(idx_t)-t_out(j))>abs(dt(j))
        t_in(idx_t)=nan;
        r_in(:,idx_t)
        continue;
    end
    for i=1:size(r_out,1)
        [~,idx_r]=nanmin(abs(r_out(i,j)-r_in(:,idx_t)));
        if abs(r_in(idx_r,idx_t)-r_out(i,j))<=abs(dr(i,j))
            mask_out(i,j)=1;
            mask_in(idx_r,idx_t)=1;
        end
        r_in(idx_r,idx_t)=nan;
    end
    
end
mask_in=mask_in>0;
mask_out=mask_out>0;


end
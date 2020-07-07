function [output_2D,output_type,regs,regCellInt,shadow_height_est]=slice_transect2D_new_int(trans_obj,varargin)

p = inputParser;


addRequired(p,'trans_obj',@(trans_obj) isa(trans_obj,'transceiver_cl'));
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl')|isempty(x));
addParameter(p,'survey_options',survey_options_cl,@(x) isa(x,'survey_options_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'keep_all',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'tag_sliced_output',true,@(x) isnumeric(x)||islogical(x));
addParameter(p,'output_type',{'Surface' 'Transducer' 'Bottom'},@iscell);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});

if isempty(p.Results.block_len)
    block_len=get_block_len(100,'cpu');
else
    block_len= p.Results.block_len;
end

surv_opt_obj=p.Results.survey_options;
Vertical_slice_size=surv_opt_obj.Vertical_slice_size;
Vertical_slice_units=surv_opt_obj.Vertical_slice_units;
Horizontal_slice_size=surv_opt_obj.Horizontal_slice_size;

depthBounds=[surv_opt_obj.DepthMin surv_opt_obj.DepthMax];
rangeBounds=[surv_opt_obj.RangeMin surv_opt_obj.RangeMax];
refRangeBounds=[surv_opt_obj.RefRangeMin surv_opt_obj.RefRangeMax];

if p.Results.timeBounds(1)<=0
    st=trans_obj.Time(1);
else
    st=p.Results.timeBounds(1);
end

if p.Results.timeBounds(2)==1||isinf(p.Results.timeBounds(2))
    et=trans_obj.Time(end);
else
    et=p.Results.timeBounds(2);
end


switch lower(surv_opt_obj.IntRef)
    case {'surface' 'transducer' 'bottom'}
        output_type = {surv_opt_obj.IntRef};
    otherwise
        output_type = {'Surface' 'Transducer' 'Bottom'};
end

if surv_opt_obj.Shadow_zone>0
    output_type=union(output_type,'Shadow');
end

t_depth=trans_obj.get_transducer_depth();
t_depth=unique(t_depth);

switch lower(surv_opt_obj.IntType)
    case 'by regions'
        slice_int = true;
        intersect_only=1;
        reg_int = true;
    case 'wc'
        slice_int = true;
        intersect_only=0;    
        reg_int = false;
    case 'regions only'
        slice_int = false;
        intersect_only=1;
        reg_int = true;
    otherwise
        slice_int = true;
        intersect_only=1;
        reg_int = true;
end

if all(t_depth==0) && ismember('Surface',output_type) && intersect_only ==0
    output_type(strcmpi(output_type,'Transducer'))=[];
end

bot_range=trans_obj.get_bottom_range();

if all(isnan(bot_range))
    output_type(strcmpi(output_type,'Bottom'))=[];
end

output_2D=cell(1,numel(output_type));
idx_reg=cell(1,numel(output_type));
regs_ref=cell(1,numel(output_type));

if slice_int   
        for ity=1:numel(output_type)
            idx_reg{ity}=find_regions_ref(trans_obj,output_type{ity});
            idx_reg{ity}=intersect(idx_reg{ity},p.Results.idx_regs);
            
            if ~isempty(p.Results.regs)&&intersect_only
                regs_ref{ity}=p.Results.regs(strcmp({p.Results.regs(:).Reference},output_type{ity}));
            else
                regs_ref{ity}=region_cl.empty();
            end
        end
    
    int_trans=all(cellfun(@isempty,idx_reg))&&all(cellfun(@isempty,regs_ref));
    
    for ity=1:numel(output_type)
        if strcmpi(output_type{ity},'Shadow')
            continue;
        end
        
        
        if ~isempty(idx_reg{ity})||~isempty(regs_ref{ity})||intersect_only==0||(int_trans&&all(cellfun(@isempty,output_2D)))
            reg_wc=trans_obj.create_WC_region(...
                'y_min',-Inf,...
                'y_max',Inf,...
                'Type','Data',...
                'Ref',output_type{ity},...
                'Cell_w',Vertical_slice_size,...
                'Cell_h',Horizontal_slice_size,...
                'Cell_w_unit',Vertical_slice_units,...
                'Cell_h_unit','meters',...
                'block_len',block_len,...
                'Remove_ST',surv_opt_obj.Remove_ST);
            
            if  ~isempty(reg_wc)
                output_2D{ity}=trans_obj.integrate_region(reg_wc,...
                    'depthBounds',depthBounds,...
                    'rangeBounds',rangeBounds,...
                    'refRangeBounds',refRangeBounds,...
                    'timeBounds',[st et],...
                    'idx_regs',idx_reg{ity},...
                    'regs',regs_ref{ity},...
                    'select_reg','selected',...
                    'intersect_only',intersect_only,...
                    'denoised',surv_opt_obj.Denoised,...
                    'motion_correction',surv_opt_obj.Motion_correction,...
                    'keep_all',1,...
                    'sv_thr',surv_opt_obj.SvThr,...
                    'block_len',block_len,...
                    'load_bar_comp',p.Results.load_bar_comp);
            else
                output_2D{ity}=[];
            end
        else
            output_2D{ity}=[];
        end
        
        regs_temp=trans_obj.Regions;
        
        if ~isempty(regs_temp)&&~isempty(output_2D{ity})&&p.Results.tag_sliced_output
            tmp=regs_temp.tag_sliced_output(output_2D{ity},'all');
            output_2D{ity}.Tags=tmp{1};
        elseif ~isempty(output_2D{ity})
            s_eint=gather(size(output_2D{ity}.eint));
            output_2D{ity}.Tags=strings(s_eint);
        end
    end
end


idx_reg_out=unique([idx_reg{:}]);

regCellInt=cell(1,length(idx_reg_out)+numel(p.Results.regs));
regs=cell(1,length(idx_reg_out)+numel(p.Results.regs));

if reg_int
    for i=1:length(idx_reg_out)
        regs{i}=trans_obj.Regions(idx_reg_out(i));
        regCellInt{i}=trans_obj.integrate_region(trans_obj.Regions(idx_reg_out(i)),...
            'timeBounds',[st et],...
            'depthBounds',depthBounds,...
            'rangeBounds',rangeBounds,...
            'refRangeBounds',refRangeBounds,...
            'sv_thr',surv_opt_obj.SvThr,...
            'denoised',surv_opt_obj.Denoised,...
            'motion_correction',surv_opt_obj.Motion_correction,...
            'load_bar_comp',p.Results.load_bar_comp,...
            'block_len',block_len,...
            'keep_all',p.Results.keep_all,....
            'keep_bottom',p.Results.keep_bottom);
    end
    for i=1:length(p.Results.regs)
        regs{i+length(idx_reg_out)}=p.Results.regs(i);
        regCellInt{i+length(idx_reg_out)}=trans_obj.integrate_region(p.Results.regs(i),...
            'timeBounds',[st et],...
            'depthBounds',depthBounds,...
            'rangeBounds',rangeBounds,....
            'refRangeBounds',refRangeBounds,...
            'sv_thr',surv_opt_obj.SvThr,...
            'denoised',surv_opt_obj.Denoised,....
            'motion_correction',surv_opt_obj.Motion_correction,.....
            'load_bar_comp',p.Results.load_bar_comp,....
            'block_len',block_len,...
            'keep_all',p.Results.keep_all,....
            'keep_bottom',p.Results.keep_bottom);
    end
else
    regs=[];
    regCellInt={};
end

idx_sh=find(strcmpi(output_type,'Shadow'));
idx_filled=find(~cellfun(@isempty,output_2D),1);

if(~isempty(idx_reg_out)||~isempty(p.Results.regs))&&surv_opt_obj.Shadow_zone>0
    [output_2D{idx_sh},~,shadow_height_est_temp]=trans_obj.estimate_shadow_zone(...
        'Shadow_zone_height',surv_opt_obj.Shadow_zone_height,...
        'timeBounds',[st et],...
        'Vertical_slice_size',Vertical_slice_size,'Slice_units',Vertical_slice_units,...
        'Denoised',surv_opt_obj.Denoised,...
        'Motion_correction',surv_opt_obj.Motion_correction,...
        'idx_regs',idx_reg_out,...
        'sv_thr',surv_opt_obj.SvThr,...
        'regs',p.Results.regs);
    shadow_height_est=zeros(1,size(output_2D{idx_sh}.eint,2));
    
    for k=1:length(shadow_height_est)
        if ~isnan(output_shadow_reg.Ping_S(k))
            shadow_height_est(k)=nanmean(shadow_height_est_temp(output_2D{idx_sh}.Ping_S(k):output_2D{idx_sh}.Ping_E(k)));
        end
    end
else
    if ~isempty(idx_filled)
        shadow_height_est=zeros(1,size(output_2D{idx_filled}.Ping_E,2));
    else
        shadow_height_est=[];
    end
end

idx_rem=cellfun(@isempty,output_2D);
output_2D(idx_rem)=[];
output_type(idx_rem)=[];

end
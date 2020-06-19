function [data,idx_r,idx_pings,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st] = get_data_from_region(trans_obj,region,varargin)

%% input parser
p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'region',@(x) isa(x,'region_cl'));
addParameter(p,'timeBounds',[0 Inf],@isnumeric);
addParameter(p,'depthBounds',[-inf inf],@isnumeric);
addParameter(p,'rangeBounds',[-inf inf],@isnumeric);
addParameter(p,'refRangeBounds',[-inf inf],@isnumeric);
addParameter(p,'field','sv',@ischar);
addParameter(p,'intersect_only',false,@(x) isnumeric(x)||islogical(x));
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'line_obj',[],@(x) isa(x,'line_cl')||isempty(x));
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'select_reg','all',@ischar);
addParameter(p,'keep_bottom',false,@(x) isnumeric(x)||islogical(x));
parse(p,trans_obj,region,varargin{:});

%% init
data = [];
idx_r = [];
idx_pings = [];
bad_data_mask = [];
intersection_mask = [];
bad_trans_vec = [];
below_bot_mask = [];
mask_from_st = [];

idx_pings_tot = region.Idx_pings;

time_tot = trans_obj.get_transceiver_time(idx_pings_tot);

idx_keep_x = ( time_tot<=p.Results.timeBounds(2) & time_tot>=p.Results.timeBounds(1) );

if ~any(idx_keep_x)
    return;
end
idx_pings = idx_pings_tot(idx_keep_x);
idx_r = region.Idx_r;

% tic
% [ping_mat,r_mat]=meshgrid(idx_pings,idx_r);
% isin=arrayfun(@(x,y) isinterior(region.Poly,x,y),ping_mat,r_mat);
% toc
% figure();imagesc(isin)
% tic
% isin_2=region.Poly.isinterior(ping_mat(:),r_mat(:));
% isin_2=reshape(isin,size(ping_mat));
% toc

range_trans = trans_obj.get_transceiver_range(idx_r);
idx_r = idx_r(range_trans>nanmin(p.Results.rangeBounds)&range_trans<nanmax(p.Results.rangeBounds));

data = trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field',p.Results.field);
depth_trans = trans_obj.get_transceiver_depth(idx_r,idx_pings);
range_trans = trans_obj.get_transceiver_range(idx_r);
bot_sple = trans_obj.get_bottom_idx(idx_pings);
bot_sple(isnan(bot_sple)) = inf;
[~,idx_keep_r] = intersect(idx_r,region.Idx_r);

if isempty(data)
    warning('No such data');
    return;
end

region.Idx_pings = idx_pings;
region.Idx_r = idx_r;

switch region.Shape
    case 'Polygon'
        region.MaskReg = region.get_sub_mask(idx_keep_r,idx_keep_x);
        data(region.get_mask==0) = NaN;
end

if isempty(idx_r)||isempty(idx_pings)
    warning('Cannot integrate this region, no data...');
    trans_obj.rm_region_id(region.Unique_ID);
    return;
end

if p.Results.intersect_only==1
    
    switch p.Results.select_reg
        case 'all'
            idx = trans_obj.find_regions_type('Data');
        otherwise
            idx = p.Results.idx_regs;
    end
    
    intersection_mask = region.get_mask_from_intersection(trans_obj.Regions(idx));
    
    if ~isempty(p.Results.regs)
        intersection_mask_2 = region.get_mask_from_intersection(p.Results.regs);
        intersection_mask   = intersection_mask_2|intersection_mask;
    end
    
else
    intersection_mask = true(size(data));
end

idx = trans_obj.find_regions_type('Bad Data');
bad_data_mask = region.get_mask_from_intersection(trans_obj.Regions(idx));

mask_spikes = trans_obj.get_spikes(idx_r,idx_pings);

if ~isempty(mask_spikes)
    bad_data_mask = bad_data_mask|mask_spikes;
end

if region.Remove_ST
    mask_from_st = trans_obj.mask_from_st();
    mask_from_st = mask_from_st(idx_r,idx_pings);
else
    mask_from_st = false(size(data));
end

bad_trans_vec = (trans_obj.Bottom.Tag(idx_pings)==0);

if p.Results.keep_bottom==0
    below_bot_mask = bsxfun(@ge,idx_r(:),bot_sple(:)');
else
    below_bot_mask = false(size(data));
end

data(depth_trans<nanmin(p.Results.depthBounds)|depth_trans>nanmax(p.Results.depthBounds))=nan;

switch region.Reference
    case 'Surface'
        line_ref = -depth_trans;
    case 'Transducer'
        line_ref = zeros(1,size(data,2));
    case 'Bottom'
        line_ref = trans_obj.get_bottom_range(idx_pings);
    case 'Line'
        if isempty(p.Results.line_obj)
            line_obj=line_cl('Depth',zeros(size(time_tot(idx_keep_x))),'Range',-depth_trans,'Time',time_tot(idx_keep_x));
        else
            line_obj=p.Results.line_obj;
        end
        line_ref = resample_data_v2(line_obj.Range,line_obj.Time,time_tot);
end

if any(~isinf(p.Results.refRangeBounds))
    if numel(unique(line_ref))==1
        range_from_line_ref=range_trans-unique(line_ref);
        data(range_from_line_ref<nanmin(p.Results.refRangeBounds)|range_from_line_ref>nanmax(p.Results.refRangeBounds),:)=nan;
    else
        range_from_line_ref=range_trans-line_ref;
        data(range_from_line_ref<nanmin(p.Results.refRangeBounds)|range_from_line_ref>nanmax(p.Results.refRangeBounds))=nan;
    end
end

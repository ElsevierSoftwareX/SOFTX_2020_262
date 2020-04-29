function reg_wc=create_WC_region(trans_obj,varargin)

%% input parser
p = inputParser;

check_w_unit = @(unit) ~isempty(strcmp(unit,{'pings','meters'}));
check_h_unit = @(unit) ~isempty(strcmp(unit,{'meters'}));
check_ref = @(ref) ~isempty(strcmp(ref,{'Surface','Bottom'}));
check_dataType = @(data) ~isempty(strcmp(data,{'Data','Bad Data'}));

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addParameter(p,'y_min',-inf,@isnumeric)
addParameter(p,'y_max',inf,@isnumeric)
addParameter(p,'t_min',0,@isnumeric)
addParameter(p,'t_max',inf,@isnumeric)
addParameter(p,'Type','Data',check_dataType);
addParameter(p,'Ref','Surface',check_ref);
addParameter(p,'Cell_w',10,@isnumeric);
addParameter(p,'Cell_h',10,@isnumeric);
addParameter(p,'Cell_w_unit','pings',check_w_unit);
addParameter(p,'Cell_h_unit','meters',check_h_unit);
addParameter(p,'Remove_ST',0,@isnumeric);
addParameter(p,'block_len',[],@(x) x>0 || isempty(x));

parse(p,trans_obj,varargin{:});

if isempty(p.Results.block_len)
    block_len=get_block_len(100,'cpu');
else
    block_len= p.Results.block_len;
end

%% cell width
switch p.Results.Cell_w_unit
    case 'pings'
        cell_w = p.Results.Cell_w;
        cell_w_units = 'pings';
    case 'meters'
        if ~isempty(trans_obj.GPSDataPing.Dist)
            cell_w = p.Results.Cell_w;
            cell_w_units = 'meters';
        else
            cell_w_units = 'pings';
            cell_w = p.Results.Cell_w;
        end
    case 'seconds'
        cell_w_units = 'seconds';
        cell_w = p.Results.Cell_w;
end


ydata = trans_obj.get_transceiver_range();
bot_data = trans_obj.get_bottom_range();
trans_depth=trans_obj.get_transducer_depth();


%% ?
time_t = trans_obj.get_transceiver_time();
idx_pings = find( time_t >= p.Results.t_min & time_t <= p.Results.t_max );
bot_data(trans_obj.get_bottom_idx() == numel(ydata)) = nan;
bot_data = bot_data(idx_pings);
trans_depth=trans_depth(idx_pings);
nb_pings = length(bot_data);
name = 'WC';
%% region reference
shape= 'Rectangular';
off=0;
switch lower(p.Results.Ref)
    case 'transducer'

    case 'surface'
        line_ref=trans_depth;
        if numel(unique(trans_depth))==1
            off=unique(trans_depth);
        else
            shape='Polygon';
            line_ref=-trans_depth;
            r_min=-p.Results.y_max;
            r_max=-p.Results.y_min;
        end
    case 'bottom'
        shape='Polygon';
        line_ref=bot_data;
        r_max=p.Results.y_max;
        r_min=p.Results.y_min;
    otherwise
        warning('Reference %s not recognized, treating that as transducer based integration...',p.Results.Ref)
end


switch shape
    
    case 'Rectangular'
         idx_r_min = find(ydata >= p.Results.y_min,1,'first');
        
        idxBad = trans_obj.Bottom.Tag == 0;
        if all(~isnan(bot_data(~idxBad)))
            [~,idx_r_max] = nanmin(abs(ydata-off-(nanmax(bot_data+p.Results.Cell_h))));
        else
            idx_r_max = length(ydata);
        end
        
        if p.Results.y_max ~= Inf
            idx_r_y_max = find(ydata-off<=p.Results.y_max,1,'last');
            idx_r_max   = nanmin(idx_r_max,idx_r_y_max);
        end
        mask = [];
        idx_r = idx_r_min:idx_r_max;
        
    case 'Polygon'
        
        mask = false(numel(ydata),nb_pings);
        block_size = ceil(block_len/numel(ydata));
        num_ite = ceil(nb_pings/block_size);
        
        for ui = 1:num_ite
            idx_pings_red = idx_pings((ui-1)*block_size+1:nanmin(ui*block_size,nb_pings));
            mask(:,idx_pings_red) = bsxfun( @ge, ydata, line_ref(idx_pings_red)-r_max ) & ...
                bsxfun( @le, ydata, line_ref(idx_pings_red)-r_min );
        end
        
        idx_r = find(nansum(mask,2)>0,1,'first'):find(nansum(mask,2)>0,1,'last');
        mask = mask(idx_r,:);
        
end

if isempty(idx_r)||isempty(idx_pings)
    reg_wc = [];
else
    reg_wc = region_cl(...
        'ID',trans_obj.new_id(),...
        'Shape',shape,...
        'MaskReg',mask,...
        'Name',name,...
        'Type',p.Results.Type,...
        'Idx_pings',idx_pings,...
        'Idx_r',idx_r,...
        'Reference',p.Results.Ref,...
        'Cell_w',cell_w,...
        'Cell_w_unit',cell_w_units,...
        'Cell_h',p.Results.Cell_h,...
        'Cell_h_unit',p.Results.Cell_h_unit,...
        'Remove_ST',p.Results.Remove_ST);
end

end

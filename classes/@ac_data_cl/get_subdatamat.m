function [datamat,sc] = get_subdatamat(data,idx_r,idx_ping,varargin)

p = inputParser;

addRequired(p,'data',@(x) isa(data,'ac_data_cl'));
addRequired(p,'idx_r',@isnumeric);
addRequired(p,'idx_ping',@isnumeric);
addParameter(p,'field','sv',@ischar);


parse(p,data,idx_r,idx_ping,varargin{:});

field=p.Results.field;

if isempty(idx_r)
    idx_r=data.get_samples();
end

if isempty(idx_ping)
    idx_ping=1:data.Nb_pings;
end

[idx,found]=find_field_idx(data,lower(deblank(field)));

sc=data.SubData(idx).Scale;
if found
    datamat=nan(length(idx_r),length(idx_ping));
    
    for icell=1:length(data.SubData(idx).Memap)
        idx_ping_cell=find(data.BlockId==icell);
        [idx_ping_cell_red,idx_ping_temp,~]=intersect(idx_ping,idx_ping_cell);
        
        if ~isempty(idx_ping_temp)
            idx_r_tmp=idx_r(idx_r<=size(data.SubData(idx).Memap{icell}.Data.(lower(deblank(field))),1)&idx_r>0);
            data_tmp=data.SubData(idx).Memap{icell}.Data.(lower(deblank(field)))(idx_r_tmp,idx_ping_cell_red-idx_ping_cell(1)+1);
            switch data.SubData(idx).Fmt
                case {'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint164'}
                    if data.SubData(idx).ConvFactor<0
                        idx_nan=data_tmp==intmax(data.SubData(idx).Fmt);
                    else
                        idx_nan=data_tmp==intmin(data.SubData(idx).Fmt);
                    end
                              
                case {'single' 'double'}
                    idx_nan=(data_tmp==realmin(data.SubData(idx).Fmt));
            end
            
            val=data.SubData(idx).DefaultValue;
            data_tmp=double(data.SubData(idx).ConvFactor)*double(data_tmp);
            %data_tmp(idx_nan)=nan;
            data_tmp(idx_nan)=val;
            datamat(1:size(data_tmp,1),idx_ping_temp)=data_tmp;
            if size(data_tmp,1)<size(datamat,1)
                datamat(size(data_tmp,1)+1:end,idx_ping_temp)=val;
            end
        end
    end
else
    datamat=[];
end


end
function [datamat,sc] = get_subdatamat(data_obj,varargin)

p = inputParser;

addRequired(p,'data_obj',@(x) isa(x,'ac_data_cl'));
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'field','sv',@ischar);


parse(p,data_obj,varargin{:});

idx_r = p.Results.idx_r;
idx_beam = p.Results.idx_beam;
idx_ping = p.Results.idx_ping;
field=p.Results.field;


if isempty(idx_r)
    idx_r=data_obj.get_samples();
end

if isempty(idx_ping)
    idx_ping=1:data_obj.Nb_pings;
end

if isempty(idx_beam)
    idx_beam=1:nanmax(data_obj.Nb_beams);
end

[idx,found]=data_obj.find_field_idx(lower(deblank(field)));

sc=data_obj.SubData(idx).Scale;

if found
    if nanmax(data_obj.Nb_beams)>1
        datamat=nan(length(idx_r),length(idx_beam),length(idx_ping));
    else
        datamat=nan(length(idx_r),length(idx_ping));
    end
    
    for icell=1:length(data_obj.SubData(idx).Memap)
        idx_ping_cell=find(data_obj.BlockId==icell);
        [idx_ping_cell_red,idx_ping_temp,~]=intersect(idx_ping,idx_ping_cell);
        
        if ~isempty(idx_ping_temp)
            idx_r_tmp=idx_r(idx_r<=size(data_obj.SubData(idx).Memap{icell}.Data.(lower(deblank(field))),1)&idx_r>0);
            
            if numel(size(data_obj.SubData(idx).Memap{icell}.Data.(lower(deblank(field)))))==3
                idx_beam_tmp=idx_beam(idx_beam<=size(data_obj.SubData(idx).Memap{icell}.Data.(lower(deblank(field))),2)&idx_beam>0);
                data_tmp=data_obj.SubData(idx).Memap{icell}.Data.(lower(deblank(field)))(idx_r_tmp,idx_beam_tmp,idx_ping_cell_red-idx_ping_cell(1)+1);
            else
                data_tmp=data_obj.SubData(idx).Memap{icell}.Data.(lower(deblank(field)))(idx_r_tmp,idx_ping_cell_red-idx_ping_cell(1)+1);
            end
            switch data_obj.SubData(idx).Fmt
                case {'int8' 'uint8' 'int16' 'uint16' 'int32' 'uint32' 'int64' 'uint164'}
                    if data_obj.SubData(idx).ConvFactor<0
                        idx_nan=data_tmp==intmax(data_obj.SubData(idx).Fmt);
                    else
                        idx_nan=data_tmp==intmin(data_obj.SubData(idx).Fmt);
                    end
                              
                case {'single' 'double'}
                    idx_nan=(data_tmp==realmin(data_obj.SubData(idx).Fmt));
            end
            
            val=data_obj.SubData(idx).DefaultValue;
            data_tmp=double(data_obj.SubData(idx).ConvFactor)*double(data_tmp);
            data_tmp(idx_nan)=val;
            
            datamat(1:size(data_tmp,1),idx_ping_temp)=data_tmp;
            
            if numel(size(datamat))==3
                if size(data_tmp,1)<size(datamat,1)
                    datamat(size(data_tmp,1)+1:end,:,idx_ping_temp)=val;
                end
            else
                if size(data_tmp,1)<size(datamat,1)
                    datamat(size(data_tmp,1)+1:end,idx_ping_temp)=val;
                end
            end
        end
    end
else
    datamat=[];
end


end
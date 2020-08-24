function replace_sub_data_v2(data_obj,data_mat,varargin)

if isempty(data_mat)
    return;
end

p = inputParser;

addRequired(p,'data_obj',@(x) isa(x,'ac_data_cl'));
addRequired(p,'data_mat',@isnumeric);
addParameter(p,'idx_r',[],@isnumeric);
addParameter(p,'idx_beam',[],@isnumeric);
addParameter(p,'idx_ping',[],@isnumeric);
addParameter(p,'field','sv',@ischar);

parse(p,data_obj,data_mat,varargin{:});

idx_r = p.Results.idx_r;
idx_beam = p.Results.idx_beam;
idx_ping = p.Results.idx_ping;
field=p.Results.field;


[idx,found]=data_obj.find_field_idx(field);
[fields,~,fmt_fields,factor_fields,default_values]=init_fields();

idx_field=strcmpi(field,fields);

if ~any(idx_field)&&contains(lower(field),'khz')
    idx_field=contains(fields,'khz');
end

default_value=default_values(idx_field);

if found==0
    data_obj.init_sub_data(field,default_value);
    [idx,~]=find_field_idx(data_obj,field);
end
nb_pings=data_obj.get_nb_pings_per_block();
nb_beams=data_obj.Nb_beams;
nb_samples=data_obj.Nb_samples;

if numel(data_mat)>1
    [data_mat_cell,idx_r_cell,idx_beam_cell,idx_ping_cell]=divide_mat_v2(data_mat,nb_samples,nb_beams,nb_pings,idx_r,idx_beam,idx_ping,nanmax(data_obj.Nb_beams)>1);
    
    for ii=1:length(data_mat_cell)
        if ~isempty(idx_ping_cell{ii})&&~isempty(idx_r_cell{ii})&&~isempty(idx_beam_cell{ii})
            nb_samples_data=size(data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field))),1);
            nb_samples_data_cell=size(data_mat_cell{ii},1);
            
            idx_r=idx_r_cell{ii};
            idx_r(idx_r_cell{ii}>nb_samples_data)=[];
            idx_r((idx_r-idx_r(1)+1)>nb_samples_data_cell)=[];
            idx_r_data=idx_r-idx_r(1)+1;
            
            if ~nanmax(data_obj.Nb_beams)>1
                data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(idx_r,idx_ping_cell{ii})=data_mat_cell{ii}(idx_r_data,:)/data_obj.SubData(idx).ConvFactor;
            else
                nb_beams_data=size(data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field))),2);
                nb_beams_data_cell=size(data_mat_cell{ii},2);
                
                idx_beam=idx_beam_cell{ii};
                idx_beam(idx_beam_cell{ii}>nb_beams_data)=[];
                idx_beam((idx_beam-idx_beam(1)+1)>nb_beams_data_cell)=[];
                idx_beam_data=idx_beam-idx_beam(1)+1;
                
                data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(idx_r,idx_beam,idx_ping_cell{ii})=data_mat_cell{ii}(idx_r_data,idx_beam_data,:)/data_obj.SubData(idx).ConvFactor;
                
            end
        end
        data_mat_cell{ii}=[];
    end
else
    for ii=1:length(nb_samples)
        data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(:)=data_mat/data_obj.SubData(idx).ConvFactor;
    end 
end
end

%% create_regions_from_linked_candidates.m
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
% * |trans|: TODO: write description and info on variable
% * |linked_candidates|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
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
function id_rem=create_regions_from_linked_candidates(trans,linked_candidates,varargin)

p = inputParser;

check_w_unit=@(unit) ~isempty(strcmp(unit,{'pings','meters'}));
check_h_unit=@(unit) ~isempty(strcmp(unit,{'meters'}));

addRequired(p,'trans',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'linked_candidates',@(x) isnumeric(x)||isstring(x));
addParameter(p,'idx_pings',1:size(linked_candidates,2),@isnumeric);
addParameter(p,'idx_r',1:size(linked_candidates,1),@isnumeric);
addParameter(p,'w_unit','pings',check_w_unit);
addParameter(p,'h_unit','meters',check_h_unit);
addParameter(p,'cell_w',10);
addParameter(p,'cell_h',5);
addParameter(p,'ref','Transducer');
addParameter(p,'reg_names','School',@ischar);
addParameter(p,'rm_overlapping_regions',true,@islogical);
addParameter(p,'tag','',@(x) ischar(x)||istring(x));
addParameter(p,'bbox_only',0);


parse(p,trans,linked_candidates,varargin{:});

w_unit=p.Results.w_unit;
h_unit=p.Results.h_unit;
cell_h=p.Results.cell_h;
cell_w=p.Results.cell_w;

bbox_only=p.Results.bbox_only;
ref=p.Results.ref;

reg_schools=trans.get_region_from_name(p.Results.reg_names);

[classes,id_classes,ic]=unique(linked_candidates);
% 
% 
if isstring(classes)
    ic(ic==id_classes(id_classes==find(classes=="")))=0;
    classes(classes=="")=[];
    tags=classes;
    classes=unique(ic);
    classes(classes==0)=[];
    linked_candidates=reshape(ic,size(linked_candidates));
else
    classes(classes==0)=[];
    tags=strings(size(classes));
    tags(:) = p.Results.tag;
end

idx_pings=nanmin(floor(p.Results.idx_pings)):nanmax(ceil(p.Results.idx_pings));
idx_r=nanmin(floor(p.Results.idx_r)):nanmax(ceil(p.Results.idx_r));

if ~all([numel(idx_r) numel(idx_pings)]==size(linked_candidates)) 
    x=repmat(p.Results.idx_pings,size(linked_candidates,1),1);
    F = scatteredInterpolant(x(p.Results.idx_r>0),p.Results.idx_r(p.Results.idx_r>0),linked_candidates(p.Results.idx_r>0),'nearest');
    [x_tot,y_tot]=meshgrid(idx_pings,idx_r);
    linked_candidates=F(x_tot,y_tot);
end



for j=1:numel(classes)
    
    curr_reg=(linked_candidates==classes(j));    
    [J,I]=find(curr_reg);
    
    if ~isempty(J)
        ping_ori=nanmax(nanmin(I),1);
        sample_ori=nanmax(nanmin(J),1);
        
        Bbox_w=(nanmax(I)-nanmin(I));
        Bbox_h=(nanmax(J)-nanmin(J));
        
        idx_pings_sub=ping_ori:ping_ori+Bbox_w-1;
        idx_r_sub=sample_ori:sample_ori+Bbox_h-1;
        
        
        if bbox_only==1
            reg_temp=region_cl(...
                'ID',trans.new_id(),...
                'Name',p.Results.reg_names,...
                'Type','Data',...
                'Idx_pings',idx_pings_sub+idx_pings(1)-1,...
                'Idx_r',idx_r_sub+idx_r(1)-1,...
                'Shape','Rectangular',...
                'Reference',ref,...
                'Cell_w',cell_w,...
                'Cell_w_unit',w_unit,...
                'Cell_h',cell_h,...
                'Cell_h_unit',h_unit,'Tag',char(tags(j)));
        else
            
            reg_temp=region_cl(...
                'ID',trans.new_id(),...
                'Name',p.Results.reg_names,...
                'Type','Data',...
                'Idx_pings',idx_pings_sub+idx_pings(1)-1,...
                'Idx_r',idx_r_sub+idx_r(1)-1,...
                'Shape','Polygon',...
                'MaskReg',full(curr_reg(idx_r_sub,idx_pings_sub)),...
                'Reference',ref,...
                'Cell_h',cell_h,...
                'Cell_h_unit',h_unit,...
                'Cell_w',cell_w,...
                'Cell_w_unit',w_unit,'Tag',char(tags(j)));
        end
        
        vertices_1=unique(reg_temp.Poly.Vertices(~isnan(reg_temp.Poly.Vertices(:,1)),1));
        vertices_2=unique(reg_temp.Poly.Vertices(~isnan(reg_temp.Poly.Vertices(:,2)),2));
        
        if numel(vertices_1)<2||numel(vertices_2)<2
            continue;
        end
        
        id_rem={};
        if p.Results.rm_overlapping_regions
            for i=1:length(reg_schools)
                mask_inter=reg_temp.get_mask_from_intersection(reg_schools(i));
                if any(mask_inter(:))
                    id_rem=union(id_rem,reg_schools(i).Unique_ID);
                    trans.rm_region_id(reg_schools(i).Unique_ID);
                end
            end
        end
        trans.add_region(reg_temp,'Split',0);
        
    end
end
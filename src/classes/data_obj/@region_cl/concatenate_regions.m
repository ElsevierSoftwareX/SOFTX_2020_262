function merged_reg=concatenate_regions(regions)

if isempty(regions)
    merged_reg=[];
    return;
end

idx_r=regions(1).Idx_r;
idx_ping=regions(1).Idx_ping;


%poly_union=regions(1).Poly;
for i=2:length(regions)
    idx_r=(min(idx_r(1),regions(i).Idx_r(1)):max(idx_r(end),regions(i).Idx_r(end)))';
    idx_ping=min(idx_ping(1),regions(i).Idx_ping(1)):max(idx_ping(end),regions(i).Idx_ping(end));
    %poly_union=union(poly_union,regions(i).Poly);
end

maskReg=zeros(numel(idx_r),numel(idx_ping));

for i=1:length(regions)
    maskReg(regions(i).Idx_r-idx_r(1)+1,regions(i).Idx_ping-idx_ping(1)+1)=regions(i).get_mask()+...
        maskReg(regions(i).Idx_r-idx_r(1)+1,regions(i).Idx_ping-idx_ping(1)+1);
end

maskReg=maskReg>=1;
if all(maskReg(:))
    %if length(regions)>1
    shp='Rectangular';
else
    shp=regions.Shape;
end


merged_reg=region_cl(...
    'ID',regions(1).ID,...
    'Tag',regions(1).Tag,...
    'Name',regions(1).Name,...
    'Type',regions(1).Type,...
    'Shape',shp,...
    'Idx_ping',idx_ping,...
    'Idx_r',idx_r,...
    'MaskReg',maskReg,...
    'Reference',regions(1).Reference,...
    'Cell_w',regions(1).Cell_w,...
    'Cell_w_unit',regions(1).Cell_w_unit,...
    'Cell_h',regions(1).Cell_h,...
    'Cell_h_unit',regions(1).Cell_h_unit);

end
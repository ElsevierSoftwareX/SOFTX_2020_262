function [x,y]=cont_from_mask(Mask)

Mask=filter2_perso(ones(2,2),Mask)>0;
boundaries = bwboundaries(Mask);
x=cell(1,numel(boundaries));
y=cell(1,numel(boundaries));

for i = 1 : numel(boundaries)
    x{i}=boundaries{i}(:,2);
    y{i}=boundaries{i}(:,1);
end
n=cellfun(@numel,x);
y(n<3)=[];
x(n<3)=[];


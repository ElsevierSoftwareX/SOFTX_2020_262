function [t_0,t_1]=get_time_bounds(layer_obj)

p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));

parse(p,layer_obj);

t_0=nan(1,numel(layer_obj));
t_1=nan(1,numel(layer_obj));

for il=1:numel(layer_obj)
    for i=1:length(layer_obj(il).Frequencies)
        t_0(il)=nanmin([t_0(il) layer_obj(il).Transceivers(i).Time]);
        t_1(il)=nanmax([t_1(il) layer_obj(il).Transceivers(i).Time]);
    end
end
end
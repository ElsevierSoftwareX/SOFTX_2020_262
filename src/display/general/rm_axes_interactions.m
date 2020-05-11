function rm_axes_interactions(ax)

for iax=1:numel(ax)
    disableDefaultInteractivity(ax(iax));
    ax(iax).Interactions=[];
end

end
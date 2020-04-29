function cmap_list=list_cmaps()

cpt_files=dir(fullfile(whereisEcho,'private','cmaps','*.cpt'));
cpt_files={cpt_files([cpt_files(:).isdir]==0).name};

[~,cmap_list,~]=cellfun(@fileparts,cpt_files,'un',0);


end
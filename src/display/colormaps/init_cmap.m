function [cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(cmap_name)

cmap_folder=fullfile(whereisEcho,'private','cmaps');
cmap=[];
if isfile(fullfile(cmap_folder,[cmap_name '.cpt']))
    try
        [cmap, lims, ticks, bfncol, ctable]=cpt_to_cmap(fullfile(cmap_folder,[cmap_name '.cpt'])); 
        B=bfncol(1,:);
        F=bfncol(2,:);
        N=bfncol(3,:);
    catch err
        print_errors_and_warnings([],'error',err);
        fprintf('Could not read colormap file: %s\n',fullfile(cmap_folder,[cmap_name '.cpt']));
    end
end

if isempty(cmap)
    cmap=colormap('Parula');
    B=[1 1 1];
    N=[1 1 1];
    F=[0 0 0];    
end

col_ax=B;
col_grid=F;
col_txt=F;
col_lab=F;
col_bot=F;

sc=size(cmap,1);

idx_t=nanmax(floor(sc/10),1);

col_tracks=cmap(nanmin(idx_t*6,sc),:);


end
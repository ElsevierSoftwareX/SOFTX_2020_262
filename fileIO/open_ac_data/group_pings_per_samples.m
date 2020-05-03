function [nb_samples_group,ping_group_start,ping_group_end,block_id]=group_pings_per_samples(nb_samples,pings)

nb_min_s=100;
nb_min_win=50;
%div_factor=nanmax(nanmin(nb_samples)/4,nb_min_s);
%div_factor=mode(ceil(nb_samples/nb_min_s)*nb_min_s);
perc_inc=10/100;
X_fact=prctile(ceil(nb_samples/nb_min_s)*nb_min_s,90)/prctile(floor(nb_samples/nb_min_s)*nb_min_s,10);
div_factor=(perc_inc/(X_fact-1))*min(nb_samples(nb_samples>0));
div_factor=ceil(div_factor/nb_min_s)*nb_min_s;

group_by_nb_s=ceil(nb_samples/div_factor);

idx_change=find(diff(group_by_nb_s)~=0)+1;
idx_change_2=find(diff(pings)>1)+1;

idx_change=union(idx_change,idx_change_2);

if numel(idx_change)>1
    idx_keep=findgroups(floor(cumsum(diff(idx_change))/nb_min_win));
    idx_change=splitapply(@nanmin,idx_change,[1 idx_keep]);
end
idx_new_group=unique([1 idx_change]);

ping_group_start=pings(idx_new_group);
ping_group_end=pings([idx_new_group(2:end)-1 numel(pings)]);
nb_samples_group=nan(1,numel(idx_new_group));

for uig=1:numel(idx_new_group)
    ix=ismember(pings,ping_group_start(uig):ping_group_end(uig));    
    nb_samples_group(uig)=max(nb_samples(ix));   
end
block_id=ones(1,numel(nb_samples));

for ui=1:numel(ping_group_end)    
    ping_group_start(ui)=find(pings==ping_group_start(ui),1);
    ping_group_end(ui)=find(pings==ping_group_end(ui),1);
    block_id(ping_group_start(ui):ping_group_end(ui))=ui;
end
% 
% figure();
% plot(pings,ceil(nb_samples/div_factor));hold on;plot(pings,group_by_nb_s);hold on;plot(pings,nb_samples/div_factor);
% for uil=1:numel(idx_change)
%     xline(pings(idx_change(uil)),'--k');
% end



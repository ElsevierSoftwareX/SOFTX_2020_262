function write_cmap_to_cpt(fname,cmap,B,N,F)

if isfile(fname)
    delete(fname);
end

fid=fopen(fname,'w+');

for i=1:size(cmap,1)
    fprintf(fid,'%d ',i);
    fprintf(fid,'%d ',cmap(i,:)*size(cmap,1));
    fprintf(fid,'%d ',i+1);
    fprintf(fid,'%d ',cmap(i,:)*size(cmap,1));
    fprintf(fid,'\n');
end

fprintf(fid,'B %d %d %d\n',B*size(cmap,1));
fprintf(fid,'F %d %d %d\n',F*size(cmap,1));
fprintf(fid,'N %d %d %d\n',N*size(cmap,1));

fclose(fid);



end
function [fnames,idx_keep]= filter_ac_files(filenames)

idx_keep = find(~cellfun(@isempty,regexp(filenames,'(A$|raw$|lst$|ini$|^d.*\d$)')));
fnames=filenames(idx_keep);

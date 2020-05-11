function struct2csv(s,fn,varargin)
% STRUCT2CSV(s,fn,tt,permission)
%
% Output a structure to a comma delimited file with column headers
%
%        s : any structure composed of one or more matrices and cell arrays
%       fn : file name
%       tt : ?
% permission : 'w' (default) to write/overwrite or 'a' to append to
%               existing file, not rewriting headers (for serial writing)
%
%      Given s:
%
%          s.Alpha = { 'First', 'Second';
%                      'Third', 'Fourth'};
%
%          s.Beta  = [[      1,       2;
%                            3,       4]];
%          
%          s.Gamma = {       1,       2;
%                            3,       4};
%
%          s.Epsln = [     abc;
%                          def;
%                          ghi];
% 
%      STRUCT2CSV(s,'any.csv') will produce a file 'any.csv' containing:
%
%         "Alpha",        , "Beta",   ,"Gamma",   , "Epsln",
%         "First","Second",      1,  2,      1,  2,   "abc",
%         "Third","Fourth",      3,  4,      3,  4,   "def",
%                ,        ,       ,   ,       ,   ,   "ghi",
%    
%      v.0.9 - Rewrote most of the code, now accommodates a wider variety
%              of structure children
%
% Written by James Slegers, james.slegers_at_gmail.com
% Covered by the BSD License
% Modified by Alex Schimel, NIWA (20/11/18) to allow appending
%

%% input parsing
default_tt = 0;
default_permission = 'w';
valid_permission = @(x) any(validatestring(x,{'w','a'}));

p = inputParser;

addRequired(p,'s',@isstruct);
addRequired(p,'fn',@ischar);
addOptional(p,'tt',default_tt,@isnumeric);
addOptional(p,'permission',default_permission,valid_permission);

parse(p,s,fn,varargin{:});

s  = p.Results.s;
fn = p.Results.fn;
tt = p.Results.tt;
permission = p.Results.permission;


%% function code

if exist(fn,'file')
    file_already_exists = 1;
else
    file_already_exists = 0;
end

FID = fopen(fn,permission);

headers = fieldnames(s);
m = length(headers);
sz = zeros(m,2);
t = length(s);

for rr = 1:t
    
    %% header
    l = '';
    for ii = 1:m
        if tt==1
            sz(ii,:) = size(s(rr).(headers{ii})');
        else
            sz(ii,:) = size(s(rr).(headers{ii}));
        end
        if ischar(s(rr).(headers{ii}))
            sz(ii,2) = 1;
        end
        l = [l,'"',headers{ii},'",',repmat(',',1,sz(ii,2)-1)];
    end
    
    l = [l,'\n'];
    
    % do only if permission is 'write' (overwrite) or if file doesnt exist
    if strcmp(permission,'w') || ~file_already_exists
        fprintf(FID,l);
    end
    
    %% data
    
    n = max(sz(:,1));

    for ii = 1:n
        l = '';
        for jj = 1:m

            if tt==1
                c = (s(rr).(headers{jj})');
            else
                c = (s(rr).(headers{jj}));
            end
            str = '';
            
            if sz(jj,1)<ii
                str = repmat(',',1,sz(jj,2));
            else
                if isnumeric(c)
                    for kk = 1:sz(jj,2)
                            if c(ii,kk)==round(c(ii,kk))
                                str = [str,sprintf('%d,',c(ii,kk))];
                            elseif abs(c(ii,kk))>1e-5
                                str = [str,sprintf('%f,',c(ii,kk))];
                            else
                                str = [str,sprintf('%5e,',c(ii,kk))];
                            end
                    end
                elseif islogical(c)
                    for kk = 1:sz(jj,2)
                        str = [str,num2str(double(c(ii,kk))),','];
                    end
                elseif ischar(c)
                    str = ['"',c(ii,:),'",'];
                elseif iscell(c)
                    if isnumeric(c{1,1})
                        for kk = 1:sz(jj,2)
                            if c{ii,kk}==round(c{ii,kk})
                                str = [str,sprintf('%d,',c{ii,kk})];
                            elseif c{ii,kk}>1e-5
                                str = [str,sprintf('%f,',c{ii,kk})];
                            else
                                str = [str,sprintf('%5e,',c{ii,kk})];
                            end
                        end
                    elseif islogical(c{1,1})
                        for kk = 1:sz(jj,2)
                            str = [str,num2str(double(c{ii,kk})),','];
                        end
                    elseif ischar(c{1,1})
                        for kk = 1:sz(jj,2)
                            str = [str,'"',c{ii,kk},'",'];
                        end
                    end
                end
            end
            l = [l,str];
        end
        l = [l,'\n'];
        fprintf(FID,l);
    end
    
    %% finish up
    % fprintf(FID,'\n');
    
end

fclose(FID);

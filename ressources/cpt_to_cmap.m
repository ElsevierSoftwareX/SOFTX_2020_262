 
% Adapted from the code available here (Yoann Ladroit):
% https://github.com/kakearney/cptcmap-pkg/tree/master/cptcmap licence
% under
% The MIT License (MIT)
% 
% Copyright (c) 2015 Kelly Kearney
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy of
% this software and associated documentation files (the "Software"), to deal in
% the Software without restriction, including without limitation the rights to
% use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
% the Software, and to permit persons to whom the Software is furnished to do so,
% subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
% FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
% COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
% IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

function [cmap, lims, ticks, bfncol, ctable] = cpt_to_cmap(file)

% Read file
ncol=nan;

fid = fopen(file);
txt = textscan(fid, '%s', 'delimiter', '\n');
txt = txt{1};
fclose(fid);

isheader = strncmp(txt, '#', 1);
isfooter = strncmp(txt, 'B', 1) | strncmp(txt, 'F', 1) | strncmp(txt, 'N', 1);

% Extract color data, ignore labels (errors if other text found)

ctabletxt = txt(~isheader & ~isfooter);
ctable = str2num(strvcat(txt(~isheader & ~isfooter)));
if isempty(ctable)
    nr = size(ctabletxt,1);
    ctable = cell(nr,1);
    for ir = 1:nr
        ctable{ir} = str2num(strvcat(regexp(ctabletxt{ir}, '[\d\.-]*', 'match')))';
    end
    try
        ctable = cell2mat(ctable);
    catch
        error('Cannot parse this format .cpt file yet');
    end
end

% Determine which color model is used (RGB, HSV, CMYK, names, patterns,
% mixed)

[nr, nc] = size(ctable);
iscolmodline = cellfun(@(x) ~isempty(x), regexp(txt, 'COLOR_MODEL'));
if any(iscolmodline)
    colmodel = regexprep(txt{iscolmodline}, 'COLOR_MODEL', '');
    colmodel = strtrim(lower(regexprep(colmodel, '[#=]', '')));
else
    if nc == 8
        colmodel = 'rgb';
    elseif nc == 10
        colmodel = 'cmyk';
    else
        error('Cannot parse this format .cpt file yet');
    end
end
%     try
%         temp = str2num(strvcat(txt(~isheader & ~isfooter)));
%         if size(temp,2) == 8
%             colmodel = 'rgb';
%         elseif size(temp,2) == 10
%             colmodel = 'cmyk';
%         else % grayscale, maybe others
%             error('Cannot parse this format .cpt file yet');
%         end
%     catch % color names, mixed formats, dash placeholders
%         error('Cannot parse this format .cpt file yet');
%     end
% end
%

%
% iscmod = strncmp(txt, '# COLOR_MODEL', 13);
%
%
% if ~any(iscmod)
%     isrgb = true;
% else
%     cmodel = strtrim(regexprep(txt{iscmod}, '# COLOR_MODEL =', ''));
%     if strcmp(cmodel, 'RGB')
%         isrgb = true;
%     elseif strcmp(cmodel, 'HSV')
%         isrgb = false;
%     else
%         error('Unknown color model: %s', cmodel);
%     end
% end

% Reformat color table into one column of colors

cpt = zeros(nr*2, 4);
if size(ctable,2)<8
    ctable=[ctable(:,1:4) ctable(:,1:4)];
end
cpt(1:2:end,:) = ctable(:,1:4);
cpt(2:2:end,:) = ctable(:,5:8);

% Ticks

ticks = unique(cpt(:,1));

% Choose number of colors for output

if isnan(ncol)
    
    endpoints = unique(cpt(:,1));
    
    % For gradient-ed blocks, ensure at least 4 steps between endpoints
    
    issolid = all(ctable(:,2:4) == ctable(:,6:8), 2);
    
    for ie = 1:length(issolid)
        if ~issolid(ie)
            temp = linspace(endpoints(ie), endpoints(ie+1), 11)';
            endpoints = [endpoints; temp(2:end-1)];
        end
    end
    
    endpoints = sort(endpoints);
    
    % Determine largest step size that resolves all endpoints
    
    space = diff(endpoints);
    space = unique(space);
    %     space = roundn(space, -3); % To avoid floating point issues when converting to integers
    space = ceil(space*1e3)/1e3;
    
    nspace = length(space);
    if ~isscalar(space)
        
        fac = 1;
        tol = .01;
        ite_max=1e4;
        ite=0;
        while ite<ite_max
            ite=ite+1;
            if all(space >= 1 & (abs(space - round(space))) < tol)
                space = round(space);
                break;
            else
                space = space * 10;
                fac = fac * 10;
            end
        end
        
        pairs = nchoosek(space, 2);
        np = size(pairs,1);
        commonsp = zeros(np,1);
        for ip = 1:np
            commonsp(ip) = gcd(pairs(ip,1), pairs(ip,2));
        end
        
        space = min(commonsp);
        space = space/fac;
    end
    
    ncol = (max(endpoints) - min(endpoints))./space;

    ncol=nanmin(512,ncol);
end

% Remove replicates and mimic sharp breaks

isrep =  [false; ~any(diff(cpt),2)];
cpt = cpt(~isrep,:);

difc = diff(cpt(:,1));
minspace = min(difc(difc > 0));
isbreak = [false; difc == 0];
cpt(isbreak,1) = cpt(isbreak,1) + .01*minspace;

% Parse background, foreground, and nan colors

footer = txt(isfooter);
bfncol = nan(3,3);

for iline = 1:length(footer)
    if strcmp(footer{iline}(1), 'B')
        bfncol(1,:) = str2num(regexprep(footer{iline}, 'B', ''));
    elseif strcmp(footer{iline}(1), 'F')
        bfncol(2,:) = str2num(regexprep(footer{iline}, 'F', ''));
    elseif strcmp(footer{iline}(1), 'N')
        bfncol(3,:) = str2num(regexprep(footer{iline}, 'N', ''));
    end
end

if any(isnan(bfncol(1,:)))
    bfncol(1,:)=cpt(1,2:4);
end

if any(isnan(bfncol(2,:)))
    bfncol(2,:)=cpt(end,2:4);
end

if any(isnan(bfncol(3,:)))
    bfncol(3,:)=bfncol(1,:);
end

% Convert to Matlab-format colormap and color limits

lims = [min(cpt(:,1)) max(cpt(:,1))];
endpoints = linspace(lims(1), lims(2), ncol+1);
midpoints = (endpoints(1:end-1) + endpoints(2:end))/2;

cmap = interp1(cpt(:,1), cpt(:,2:4), midpoints);

switch colmodel
    case 'rgb'
        cmap = cmap ./ 255;
        bfncol = bfncol ./ 255;
        ctable(:,[2:4 6:8]) = ctable(:,[2:4 6:8]) ./ 255;
        
    case 'hsv'
        cmap(:,1) = cmap(:,1)./360;
        cmap = hsv2rgb(cmap);
        
        bfncol(:,1) = bfncol(:,1)./360;
        bfncol = hsv2rgb(bfncol);
        
        ctable(:,2) = ctable(:,2)./360;
        ctable(:,6) = ctable(:,6)./360;
        
        ctable(:,2:4) = hsv2rgb(ctable(:,2:4));
        ctable(:,6:8) = hsv2rgb(ctable(:,6:8));
        
    case 'cmyk'
        error('CMYK color conversion not yet supported');
end

% Rouding issues: occasionally, the above calculations lead to values just
% above 1, which colormap doesn't like at all.  This is a bit kludgy, but
% should solve those issues

isnear1 = cmap > 1 & (abs(cmap-1) < 2*eps);
cmap(isnear1) = 1;
cmap(cmap<0)=0;
cmap(cmap>1)=1;
bfncol(bfncol<0)=0;
bfncol(bfncol>1)=1;
% function [cmap,B,F,N]=cpt_to_cmap(fname)
%
% fid = fopen(fname);
% S = fgetl(fid);
%
% while strcmp(S(1),'#')
%     S = fgetl(fid);
% end
%
% cdata_h = sscanf(S,'%f');
% S = fgetl(fid);
% pos=0;
% while S(1) ~= -1 && ~isletter(S(1))
%     cdata_h = [cdata_h sscanf(S,'%f')];
%     pos=ftell(fid);
%     S = fgetl(fid);
% end
% fseek(fid,pos,-1);
% B=[1 1 1];
% F=[0 0 0];
% N=[0 0 0];
% A=textscan(fid,'%1c %f %f %f\n',3);
%
% fclose(fid);
% c_temp=cdata_h([2 3 4 6 7 8],:);
% c_temp_tot=nan(3,size(c_temp,2)*2);
% c_temp_tot(:,1:2:end)=c_temp(1:3,:);
% c_temp_tot(:,2:2:end)=c_temp(4:6,:);
% c_map=unique(c_temp_tot','stable','rows');
% d=nanmax(c_map(:));
% d=nanmax(d,255);
% cmap = c_map/d;
%
% for ia=1:numel(A{2})
%     v=[A{2}(ia) A{3}(ia) A{4}(ia)]/d;
%     v(v>1)=1;
%     switch A{1}(ia)
%         case 'B'
%             B=v;
%         case 'F'
%             F=v;
%         case 'N'
%             N=v;
%     end
% end
%


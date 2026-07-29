function [mse_values, scale_axis] = mse_edit(nni, varargin)
% MSE_EDIT  Multiscale sample entropy of an NN-interval series.
% Called as [mse_values, scale_axis] = mse_edit(nni,'mse_max_scale',S,...
%           'sampen_m',m,'sampen_r',r). mse_values(1) is the sample entropy.
p = inputParser;
p.addParameter('mse_max_scale', 1);
p.addParameter('sampen_m', 2);
p.addParameter('sampen_r', 0.2);
p.parse(varargin{:});
S = p.Results.mse_max_scale; m = p.Results.sampen_m; r = p.Results.sampen_r;
x = nni(:);
scale_axis = 1:S;
mse_values = nan(S,1);
for s = 1:S
    cg = coarse_grain(x, s);
    if numel(cg) > m+1
        mse_values(s) = sampen(cg, m, r*std(cg));
    end
end
end
function y = coarse_grain(x, s)
Nc = floor(numel(x)/s);
y  = mean(reshape(x(1:Nc*s), s, Nc), 1)';
end
function e = sampen(x, m, r)
if count_matches(x,m,r)==0 || count_matches(x,m+1,r)==0
    e = NaN;
else
    e = -log(count_matches(x,m+1,r) / count_matches(x,m,r));
end
end
function c = count_matches(x, mm, r)
x = x(:); N = numel(x);
T = zeros(N-mm+1, mm);
for i = 1:mm, T(:,i) = x(i:N-mm+i); end
c = 0;
for i = 1:size(T,1)-1
    d = max(abs(T(i+1:end,:) - T(i,:)), [], 2);
    c = c + sum(d <= r);
end
end

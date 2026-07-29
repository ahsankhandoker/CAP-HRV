function [n, F, alpha1, alpha2] = dfa_edit(tnn, nni)
% DFA_EDIT  Detrended Fluctuation Analysis of an NN-interval series.
% Called as [~,~,alpha1,alpha2] = dfa_edit(tnn, nni). tnn (time axis) is
% accepted for signature compatibility; DFA is computed on the beat index.
% Returns box sizes n, fluctuation function F, and the short- (4-16 beats) and
% long-scale (16-64 beats) scaling exponents alpha1, alpha2.
if nargin < 2, nni = tnn; end
x = nni(:); N = numel(x);
y = cumsum(x - mean(x));                       % integrated (profile) series
n = unique(round(2.^(2:0.25:log2(max(8,N/4))))); % candidate box sizes
n = n(n >= 4 & n <= floor(N/4));
F = zeros(numel(n),1);
for i = 1:numel(n)
    ni = n(i); m = floor(N/ni);
    boxes = reshape(y(1:m*ni), ni, m);         % columns = non-overlapping boxes
    t = (1:ni)';
    rms = zeros(m,1);
    for j = 1:m
        c = polyfit(t, boxes(:,j), 1);         % local linear detrend
        rms(j) = sqrt(mean((boxes(:,j) - polyval(c,t)).^2));
    end
    F(i) = sqrt(mean(rms.^2));
end
ln_n = log10(n(:)); ln_F = log10(F + eps);
alpha1 = local_slope(ln_n(n>=4  & n<=16), ln_F(n>=4  & n<=16));
alpha2 = local_slope(ln_n(n>=16 & n<=64), ln_F(n>=16 & n<=64));
end
function s = local_slope(x, y)
if numel(x) < 2, s = NaN; else c = polyfit(x, y, 1); s = c(1); end
end

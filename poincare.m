function [sd1, sd2] = poincare(nni, varargin)
% POINCARE  Poincare-plot descriptors SD1, SD2 (same units as input NNI).
% Drop-in standalone replacement for the PhysioZoo mhrv 'poincare'. The
% 'plot' name/value pair is accepted and ignored. Standard definitions:
%   SD1 = sqrt(1/2) * std(diff(NN));  SD2 = sqrt(2*var(NN) - 1/2*var(diff(NN)))
nni = nni(:);
d   = diff(nni);
sd1 = sqrt(0.5) * std(d);
sd2 = sqrt(max(2*var(nni) - 0.5*var(d), 0));
end

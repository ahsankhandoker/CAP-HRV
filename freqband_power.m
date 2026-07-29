function p = freqband_power(pxx, f_axis, band)
% FREQBAND_POWER  Integrate a power spectral density over a frequency band.
% Standalone replacement for mhrv.util.freqband_power. Trapezoidal integration
% of pxx over [band(1), band(2)] on the grid f_axis.
pxx = pxx(:); f_axis = f_axis(:);
idx = f_axis >= band(1) & f_axis <= band(2);
if nnz(idx) < 2, p = 0; return; end
p = trapz(f_axis(idx), pxx(idx));
end

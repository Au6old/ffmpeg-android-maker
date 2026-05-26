#!/usr/bin/env bash

# AFFect: audio-only build
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-avdevice --disable-swscale --disable-hwaccels --disable-doc --disable-programs --disable-network"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-encoders --enable-encoder=aac,flac,vorbis,libopus,libmp3lame,pcm_s16le,pcm_s24le,pcm_f32le,pcm_s32le,alac,wavpack,mp2,pcm_u8,pcm_alaw,pcm_mulaw"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-decoders --enable-decoder=mp3,mp3float,aac,aac_fixed,flac,vorbis,opus,pcm_s16le,pcm_s24le,pcm_f32le,pcm_s32le,alac,wavpack,wmav1,wmav2,wmavoice,wmalossless,ape,ac3,eac3,dts,mp2,amrnb,amrwb,pcm_u8,pcm_alaw,pcm_mulaw,adpcm_ima_wav,gsm,speex,truehd,mlp"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-filters --enable-filter=afade,aresample,volume,loudnorm,dynaudnorm,atrim,aecho,equalizer,bass,treble,highpass,lowpass,bandpass,acompressor,atempo,silencedetect,silenceremove,amix,anlmdn,agate,pan,channelmap,anull,aformat,asetrate,apad,amerge,asplit,adelay,aloop,aeval,afftdn,abuffer,abuffersink"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-muxers --enable-muxer=mp3,adts,ipod,flac,ogg,opus,wav,aiff,matroska,mp4,tta,null,amr,gsm"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-demuxers --enable-demuxer=mp3,aac,mov,flac,ogg,wav,aiff,matroska,ape,tta,wavpack,dts,ac3,eac3,asf,rm,amr,gsm,concat,truehd,dsf"
EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-protocols --enable-protocol=file,pipe,fd"

case $ANDROID_ABI in
  x86)
    # Disabling assembler optimizations, because they have text relocations
    EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --disable-asm"
    ;;
  x86_64)
    EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --x86asmexe=${NASM_EXECUTABLE}"
    ;;
esac
if [ "$FFMPEG_GPL_ENABLED" = true ] ; then
    EXTRA_BUILD_CONFIGURATION_FLAGS="$EXTRA_BUILD_CONFIGURATION_FLAGS --enable-gpl"
fi
# Preparing flags for enabling requested libraries
ADDITIONAL_COMPONENTS=
for LIBARY_NAME in ${FFMPEG_EXTERNAL_LIBRARIES[@]}
do
  ADDITIONAL_COMPONENTS+=" --enable-$LIBARY_NAME"
done
# Referencing dependencies without pkgconfig
DEP_CFLAGS="-I${BUILD_DIR_EXTERNAL}/${ANDROID_ABI}/include"
DEP_LD_FLAGS="-L${BUILD_DIR_EXTERNAL}/${ANDROID_ABI}/lib $FFMPEG_EXTRA_LD_FLAGS"
# Android 15 with 16 kb page size support
# https://developer.android.com/guide/practices/page-sizes#compile-r27
EXTRA_LDFLAGS="-Wl,-z,max-page-size=16384 $DEP_LD_FLAGS"
./configure \
  --prefix=${BUILD_DIR_FFMPEG}/${ANDROID_ABI} \
  --enable-cross-compile \
  --target-os=android \
  --arch=${TARGET_TRIPLE_MACHINE_ARCH} \
  --sysroot=${SYSROOT_PATH} \
  --cc=${FAM_CC} \
  --cxx=${FAM_CXX} \
  --ld=${FAM_LD} \
  --ar=${FAM_AR} \
  --as=${FAM_CC} \
  --nm=${FAM_NM} \
  --ranlib=${FAM_RANLIB} \
  --strip=${FAM_STRIP} \
  --extra-cflags="-O3 -fPIC $DEP_CFLAGS" \
  --extra-ldflags="$EXTRA_LDFLAGS" \
  --enable-shared \
  --disable-static \
  --disable-vulkan \
  --pkg-config=${PKG_CONFIG_EXECUTABLE} \
  ${EXTRA_BUILD_CONFIGURATION_FLAGS} \
  $ADDITIONAL_COMPONENTS || exit 1
${MAKE_EXECUTABLE} clean
${MAKE_EXECUTABLE} -j${HOST_NPROC}
${MAKE_EXECUTABLE} install

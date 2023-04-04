import json
import os
import re
import subprocess
import sys
import time
from urllib.request import getproxies

import chardet
from yt_dlp import FFmpegPostProcessor
from yt_dlp.downloader.external import Aria2cFD, FFmpegFD
from yt_dlp.postprocessor.ffmpeg import EXT_TO_OUT_FORMATS
from yt_dlp.utils import encodeArgument, Popen, RetryManager, encodeFilename, traverse_obj, handle_youtubedl_headers, \
    determine_ext, remove_end

from common import convert_unit_bytes, getSystemProxies, flush_print, converter_time_second, MsgType


class HitpawAria2cFD(Aria2cFD):
    def extract_progress_information(self,line):
        downloaded_bytes = 0
        downloaded_number = ""
        downloaded_unit = ""
        download_number = ""
        download_unit = ""

        searched = re.search("\[#[\da-zA-z]+ (\d+\.?\d*)([a-zA-Z]+)/\d+\.?\d*[a-zA-Z]+\(\d+%\) [a-zA-Z]+:\d+ DL:(\d+\.?\d*)([a-zA-Z]+)", line)
        if searched:
            downloaded_number, downloaded_unit, download_number, download_unit = searched.groups()
            downloaded_bytes = convert_unit_bytes(downloaded_number, downloaded_unit)
            download_bytes = convert_unit_bytes(download_number,download_unit)
            if downloaded_bytes!=0:
                self._hook_progress({"status":"downloading","downloaded_bytes":downloaded_bytes,'speed':download_bytes},{"status":"downloading","downloaded_bytes":downloaded_bytes})
        # searched = re.search("\(OK\):download completed.", line)
        # if searched:
        #     self._hook_progress({"status":"finished","total_bytes":self.total_bytes},{"status":"finished","total_bytes":self.total_bytes})
    def _call_downloader(self, tmpfilename, info_dict):
        """ Either overwrite this or implement _make_cmd """
        cmd = [encodeArgument(a) for a in self._make_cmd(tmpfilename, info_dict)]

        self._debug_cmd(cmd)
        #if sys.platform == "darwin":
        for i in range(0,len(cmd)):
            if cmd[i].find("--console-log-level=") >=0:
                cmd[i] = "--console-log-level=info"

        url = cmd[-1]
        cmd[-2] = "--save-session"
        cmd[-1] = os.path.join(os.path.dirname(tmpfilename),"aria2.session")
        if self.ydl.params.get('proxy') is None:
            proxy_dict = getproxies()
            if proxy_dict.get('http') is not None:
                self.ydl.params['proxy'] = proxy_dict['http']
        if self.ydl.params.get('proxy') is not None:
            cmd.append("--all-proxy")
            cmd.append(self.ydl.params['proxy'])
        cmd.append("--save-session-interval")
        cmd.append("1")
        cmd.append("--auto-save-interval")
        cmd.append("1")

        cmd.append("--")
        cmd.append(url)

        if 'fragments' not in info_dict:
            line_buffer = ""
            screenData = subprocess.Popen(cmd, text=True, stderr=subprocess.PIPE if self._CAPTURE_STDERR else None, stdout=subprocess.PIPE,encoding="utf-8")
            while True:
                seg = screenData.stdout.read(500)
                # fencoding = chardet.detect(seg)
                # print(fencoding)
                # seg = seg.decode("utf-8")
                #print(seg.encode("utf-8"))
                # err_line = screenData.stderr.readline().decode("utf-8")
                line_buffer += seg
                lines = re.split("[\r\n]", line_buffer)
                for line in lines[:-1]:
                    self.extract_progress_information(line)
                    # print(line)
                line_buffer = lines[-1]
                returncode = screenData.poll()
                if returncode is not None:
                    seg = screenData.stdout.read()
                    line_buffer += seg
                    lines = re.split("[\r\n]", line_buffer)
                    for line in lines:
                        self.extract_progress_information(line)
                        # print(line)
                    screenData.stdout.close()
                    break
            stderr = screenData.stderr.read()
            screenData.stderr.close()
            if returncode and stderr:
                self.to_stderr(stderr)
            else:
                self._hook_progress({"status":"downloading","speed":1024*1024,"downloaded_bytes":os.path.getsize(encodeFilename(tmpfilename))},{})
            return returncode

        skip_unavailable_fragments = self.params.get('skip_unavailable_fragments', True)

        retry_manager = RetryManager(self.params.get('fragment_retries'), self.report_retry,
                                     frag_index=None, fatal=not skip_unavailable_fragments)
        for retry in retry_manager:
            _, stderr, returncode = Popen.run(cmd, text=True, stderr=subprocess.PIPE)
            if not returncode:
                break
            # TODO: Decide whether to retry based on error code
            # https://aria2.github.io/manual/en/html/aria2c.html#exit-status
            if stderr:
                self.to_stderr(stderr)
            retry.error = Exception()
            continue
        if not skip_unavailable_fragments and retry_manager.error:
            return -1

        decrypt_fragment = self.decrypter(info_dict)
        dest, _ = self.sanitize_open(tmpfilename, 'wb')
        for frag_index, fragment in enumerate(info_dict['fragments']):
            fragment_filename = '%s-Frag%d' % (tmpfilename, frag_index)
            try:
                src, _ = self.sanitize_open(fragment_filename, 'rb')
            except OSError as err:
                if skip_unavailable_fragments and frag_index > 1:
                    self.report_skip_fragment(frag_index, err)
                    continue
                self.report_error(f'Unable to open fragment {frag_index}; {err}')
                return -1
            dest.write(decrypt_fragment(fragment, src.read()))
            src.close()
            if not self.params.get('keep_fragments', False):
                self.try_remove(encodeFilename(fragment_filename))
        dest.close()
        self.try_remove(encodeFilename('%s.frag.urls' % tmpfilename))
        return 0

class HitPawFFmpegFD(FFmpegFD):
    # frame=  101 fps= 50 q=-1.0 size=    1024kB time=00:00:03.39 bitrate=2474.4kbits/s speed=1.67x
    def extract_progress_information(self,line):
        downloaded_bytes = 0
        downloaded_number = ""
        downloaded_unit = ""
        downloaded_second = 0
        searched = re.search("frame=.+?fps=.+?q=.+?size=\s+(\d+\.?\d*)([a-zA-Z]+)\s+time=(\d\d):(\d\d):(\d\d).(\d\d)\s+bitrate=.+", line)
        if searched:
            downloaded_number, downloaded_unit,hours,minutes,seconds,millisecond = searched.groups()
            # flush_print("%s%s %s:%s:%s.%s" % (downloaded_number, downloaded_unit,hours,minutes,seconds,millisecond))
            downloaded_bytes = convert_unit_bytes(downloaded_number, downloaded_unit)
            downloaded_second = converter_time_second(hours,minutes,seconds)
            # if downloaded_bytes > 1024 * 1024 * 50:
            #     raise Exception("live stop")
            # flush_print("%d %d" % (downloaded_bytes, downloaded_second))
            self._hook_progress(
                {"status": "downloading", "downloaded_bytes": downloaded_bytes, 'speed': 1024*1024},
                {"status": "downloading", "downloaded_bytes": downloaded_bytes})

    def _call_downloader(self, tmpfilename, info_dict):
        urls = [f['url'] for f in info_dict.get('requested_formats', [])] or [info_dict['url']]
        ffpp = FFmpegPostProcessor(downloader=self)
        if not ffpp.available:
            self.report_error('m3u8 download detected but ffmpeg could not be found. Please install')
            return False
        ffpp.check_version()

        args = [ffpp.executable, '-y']

        for log_level in ('quiet', 'verbose'):
            if self.params.get(log_level, False):
                args += ['-loglevel', log_level]
                break
        # if not self.params.get('verbose'):
        #     args += ['-hide_banner']

        args += traverse_obj(info_dict, ('downloader_options', 'ffmpeg_args'), default=[])

        # These exists only for compatibility. Extractors should use
        # info_dict['downloader_options']['ffmpeg_args'] instead
        args += info_dict.get('_ffmpeg_args') or []
        seekable = info_dict.get('_seekable')
        if seekable is not None:
            # setting -seekable prevents ffmpeg from guessing if the server
            # supports seeking(by adding the header `Range: bytes=0-`), which
            # can cause problems in some cases
            # https://github.com/ytdl-org/youtube-dl/issues/11800#issuecomment-275037127
            # http://trac.ffmpeg.org/ticket/6125#comment:10
            args += ['-seekable', '1' if seekable else '0']

        http_headers = None
        if info_dict.get('http_headers'):
            youtubedl_headers = handle_youtubedl_headers(info_dict['http_headers'])
            http_headers = [
                # Trailing \r\n after each HTTP header is important to prevent warning from ffmpeg/avconv:
                # [http @ 00000000003d2fa0] No trailing CRLF found in HTTP header.
                '-headers',
                ''.join(f'{key}: {val}\r\n' for key, val in youtubedl_headers.items())
            ]
        proxy_dict = getSystemProxies()

        env = None
        proxy = self.params.get('proxy')
        if proxy is None and proxy_dict!={}:
            proxy = proxy_dict['http']
        if proxy:
            if not re.match(r'^[\da-zA-Z]+://', proxy):
                proxy = 'http://%s' % proxy

            if proxy.startswith('socks'):
                self.report_warning(
                    '%s does not support SOCKS proxies. Downloading is likely to fail. '
                    'Consider adding --hls-prefer-native to your command.' % self.get_basename())

            # Since December 2015 ffmpeg supports -http_proxy option (see
            # http://git.videolan.org/?p=ffmpeg.git;a=commit;h=b4eb1f29ebddd60c41a2eb39f5af701e38e0d3fd)
            # We could switch to the following code if we are able to detect version properly
            args += ['-http_proxy', proxy]

            env = os.environ.copy()
            env['HTTP_PROXY'] = proxy
            env['http_proxy'] = proxy

        protocol = info_dict.get('protocol')

        if protocol == 'rtmp':
            player_url = info_dict.get('player_url')
            page_url = info_dict.get('page_url')
            app = info_dict.get('app')
            play_path = info_dict.get('play_path')
            tc_url = info_dict.get('tc_url')
            flash_version = info_dict.get('flash_version')
            live = info_dict.get('rtmp_live', False)
            conn = info_dict.get('rtmp_conn')
            if player_url is not None:
                args += ['-rtmp_swfverify', player_url]
            if page_url is not None:
                args += ['-rtmp_pageurl', page_url]
            if app is not None:
                args += ['-rtmp_app', app]
            if play_path is not None:
                args += ['-rtmp_playpath', play_path]
            if tc_url is not None:
                args += ['-rtmp_tcurl', tc_url]
            if flash_version is not None:
                args += ['-rtmp_flashver', flash_version]
            if live:
                args += ['-rtmp_live', 'live']
            if isinstance(conn, list):
                for entry in conn:
                    args += ['-rtmp_conn', entry]
            elif isinstance(conn, str):
                args += ['-rtmp_conn', conn]

        start_time, end_time = info_dict.get('section_start') or 0, info_dict.get('section_end')

        for i, url in enumerate(urls):
            if http_headers is not None and re.match(r'^https?://', url):
                args += http_headers
            if start_time:
                args += ['-ss', str(start_time)]
            if end_time:
                args += ['-t', str(end_time - start_time)]

            args += self._configuration_args((f'_i{i + 1}', '_i')) + ['-i', url]

        if not (start_time or end_time) or not self.params.get('force_keyframes_at_cuts'):
            args += ['-c', 'copy']

        if info_dict.get('requested_formats') or protocol == 'http_dash_segments':
            for (i, fmt) in enumerate(info_dict.get('requested_formats') or [info_dict]):
                stream_number = fmt.get('manifest_stream_number', 0)
                args.extend(['-map', f'{i}:{stream_number}'])

        if self.params.get('test', False):
            args += ['-fs', str(self._TEST_FILE_SIZE)]

        ext = info_dict['ext']
        if protocol in ('m3u8', 'm3u8_native'):
            use_mpegts = (tmpfilename == '-') or self.params.get('hls_use_mpegts')
            if use_mpegts is None:
                use_mpegts = info_dict.get('is_live')
            if use_mpegts:
                args += ['-f', 'mpegts']
            else:
                args += ['-f', 'mp4']
                if (ffpp.basename == 'ffmpeg' and ffpp._features.get('needs_adtstoasc')) and (not info_dict.get('acodec') or info_dict['acodec'].split('.')[0] in ('aac', 'mp4a')):
                    args += ['-bsf:a', 'aac_adtstoasc']
        elif protocol == 'rtmp':
            args += ['-f', 'flv']
        elif ext == 'mp4' and tmpfilename == '-':
            args += ['-f', 'mpegts']
        elif ext == 'unknown_video':
            ext = determine_ext(remove_end(tmpfilename, '.part'))
            if ext == 'unknown_video':
                self.report_warning(
                    'The video format is unknown and cannot be downloaded by ffmpeg. '
                    'Explicitly set the extension in the filename to attempt download in that format')
            else:
                self.report_warning(f'The video format is unknown. Trying to download as {ext} according to the filename')
                args += ['-f', EXT_TO_OUT_FORMATS.get(ext, ext)]
        else:
            args += ['-f', EXT_TO_OUT_FORMATS.get(ext, ext)]

        args += self._configuration_args(('_o1', '_o', ''))

        args = [encodeArgument(opt) for opt in args]
        args.append(encodeFilename(ffpp._ffmpeg_filename_argument(tmpfilename), True))
        self._debug_cmd(args)
        if info_dict.get('is_live'):

            info = {'type': MsgType.live_info.value,
                    'msg': {
                        "path": tmpfilename
                    }}
            flush_print(json.dumps(info))
        proc = Popen(args, shell=False, text=True,stderr=subprocess.STDOUT, stdout=subprocess.PIPE,encoding="utf-8")
        try:

            for seg in iter(proc.stdout.readline, ""):
                #print(seg)

                self.extract_progress_information(seg)

            retval = proc.poll()
        except BaseException as e:
            # subprocces.run would send the SIGKILL signal to ffmpeg and the
            # mp4 file couldn't be played, but if we ask ffmpeg to quit it
            # produces a file that is playable (this is mostly useful for live
            # streams). Note that Windows is not affected and produces playable
            # files (see https://github.com/ytdl-org/youtube-dl/issues/8300).
            if "live stop" in e.__str__():
                proc.kill(timeout=None)
                retval = 0
            else:
                if isinstance(e, KeyboardInterrupt) and sys.platform != 'win32' and url not in ('-', 'pipe:'):
                    proc.communicate_or_kill(b'q')
                else:
                    proc.kill(timeout=None)
                raise
        return retval
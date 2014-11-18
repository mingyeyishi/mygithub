package  
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author gx
	 */
	public class MusicPlayer extends Sprite 
	{
		private var mySound:Sound;
		//定义一个数组以储存音乐列表
		private var aTracks:Array = ["mp3/1.mp3", "mp3/2.mp3", "mp3/3.mp3","mp3/4.mp3"];
		//定义当前播放音乐的id
		private var playId:Number = 0;
		
		
		/************ 控制音乐的播放和停止 **************/
		private var myChannel:SoundChannel = new SoundChannel();
		
		//记录音乐停止的位置
		private var pausePosition:int = 0;
		
		//记录音乐的播放状态，数值为play时表示音乐正在播放，数值为stop时表示处于停滞状态
		private var playStatus:String;
		
		/************ 控制音乐的音量和声道 **************/
		//用SoundTransform控制音乐的音量和声道，定义nVolume储存音量值，nPan储存声道值
		private var nVolume:Number = 0.5;
		private var nPan:Number = 0;
		private var myTrans:SoundTransform = new SoundTransform();
		
		/************ 音乐波形图 **************/
		private var channelLength:int = 256;
		private var soundBytes:ByteArray = new ByteArray();
		
		public function MusicPlayer() 
		{
			init();
		}
		
		
	     /************ 绘制的矩形mLoadingProgress元件就将对下载进度条进行遮罩  **************/
		private function init():void 
		{
			//初始化mLoadingProgress元件的scaleX 数值为0，这样开始时蓝色下载进度条不会以初始长度显示
			mProgress.mLoadingProgress.scaleX = 0;
			//
			mProgress.mPlayingProgress.scaleX = 0;
			this.addEventListener(Event.ENTER_FRAME, showProgress);
			
			//对bPlay和bPause按钮侦听
			bPlay.addEventListener(MouseEvent.CLICK, playSong);
			bPause.addEventListener(MouseEvent.CLICK, pauseSong);
			//变成小手
			mProgress.mJumpControl.buttonMode = true;
			//对滑块按钮侦听
			mProgress.mJumpControl.addEventListener(MouseEvent.MOUSE_DOWN, jumpMusic);
			//前进后退按钮
			bPrev.addEventListener(MouseEvent.CLICK, prevSong);
			bNext.addEventListener(MouseEvent.CLICK, nextSong);
			
			//声音
			mVolume.mDrag.addEventListener(MouseEvent.MOUSE_DOWN, dragVolumeBar);
			mVolume.mDrag.addEventListener(MouseEvent.MOUSE_UP, releaseVolumeBar);
			
			//声道
			mPan.mDrag.addEventListener(MouseEvent.MOUSE_DOWN,dragPanBar);
			mPan.mDrag.stage.addEventListener(MouseEvent.MOUSE_UP,releasePanBar);
			
			
			//调用loadSound方法加载音乐
			loadSound();
		}
		 /************ 控制声音 **************/
		private function releaseVolumeBar(e:MouseEvent):void 
		{
			mVolume.mDrag.removeEventListener( Event.ENTER_FRAME, dragVolume);
			mVolume.mBg.stopDrag();
		}
		
		private function dragVolumeBar(e:MouseEvent):void 
		{
			var scroll_rect:Rectangle = new Rectangle( mVolume.mBg.x, mVolume.mDrag.y,  mVolume.mBg.width - mVolume.mDrag.width ,0);
			mVolume.mDrag.startDrag( false, scroll_rect );
			mVolume.mDrag.addEventListener( Event.ENTER_FRAME, dragVolume);
		}
		private function dragVolume(e:Event):void
		{
			setVolume();
		}
		private function setVolume():void
		{
			nVolume = mVolume.mDrag.x/(mVolume.mBg.width-mVolume.mDrag.width);
			myTrans = new SoundTransform(nVolume, nPan);
			myChannel.soundTransform = myTrans;
		}
		
		/************ 控制声道 **************/
		
		private function dragPanBar(e:MouseEvent):void 
		{
			var scroll_rect:Rectangle = new Rectangle( mPan.mBg.x, mPan.mDrag.y,  mPan.mBg.width - mPan.mDrag.width ,0);
			mPan.mDrag.startDrag( false, scroll_rect );
			mPan.mDrag.addEventListener( Event.ENTER_FRAME, dragPan);
		}
		private function dragPan(e:Event):void
		{
			setPan();
		}
		private function releasePanBar(event:MouseEvent):void
		{
			mPan.mDrag.removeEventListener( Event.ENTER_FRAME, dragPan);
			mPan.mBg.stopDrag();
		}
		private function setPan():void 
		{
			nPan = (mPan.mDrag.x-(mPan.mBg.width-mPan.mDrag.width)/2)/((mPan.mBg.width-mPan.mDrag.width)/2);
			myTrans = new SoundTransform(nVolume, nPan);
			myChannel.soundTransform = myTrans;
		}
		
		
		 /****************************下一首*************************************/
		private function nextSong(e:MouseEvent):void 
		{
			myChannel.stop();
			playId--;
			if (playId < 0)
			{
				playId = aTracks.length-1;
			}
			loadSound();
		}
		 /****************************上一首*************************************/
		private function prevSong(e:MouseEvent):void 
		{
			myChannel.stop();
			playId++;
			if (playId >= aTracks.length)
			{
				playId = 0;
			}
			loadSound();
		}
		
		
		
		
		 /****************************滑块事件*************************************/
		private function jumpMusic(e:MouseEvent):void 
		{
			var xpos:Number = (mouseX - mProgress.mJumpControl.x - mProgress.x) / mProgress.mJumpControl.width;
			var pos:Number = mySound.length * xpos;
			myChannel.stop();
			playStatus = "play";
			myChannel = mySound.play(pos);
			myChannel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			
		}
		
		
		
		
        /****************************音乐进度条和波形图*************************************/
		private function showProgress(e:Event):void 
		{
			//使用myChannel的position获得当前音乐播放位置，使其用length属性得到音乐总长度，两者相除得到播放进度
			var playbackPercent:Number = (myChannel.position / mySound.length);
			mProgress.mPlayingProgress.scaleX = playbackPercent;
			
			//波形图
			SoundMixer.computeSpectrum(soundBytes, false, 0);
			var graphic:Graphics = mWave.graphics;
			graphic.clear();
			var n:Number = 0;
			for (var i:int = 0; i < channelLength; i++) 
			{
				n = (soundBytes.readFloat() * 100);
				if (i % 2 == 0) 
				{
					graphic.lineStyle(0, 0xFFC07B);
					graphic.moveTo(Math.round(i/2), 20);
					graphic.lineTo(Math.round(i/2), n+20);
					graphic.endFill();
				}
			}
			for (i = channelLength; i > 0; i--)
			{
				n = (soundBytes.readFloat() * 100);
				if (i % 2 == 0) 
				{
					graphic.lineStyle(0, 0x7BD8FF);
					graphic.moveTo(Math.round(i/2), 20);
					graphic.lineTo(Math.round(i/2), n+20);
					graphic.endFill();
				}
			}
		}
		
		
		
		
		/****************************音乐停止*************************************/
		private function pauseSong(e:MouseEvent):void 
		{
			if (playStatus == "play")
			{
				playStatus = "stop";
				//position属性获得音乐当前的播放位置
				pausePosition = myChannel.position;
				myChannel.stop();
				myChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			}
		}
		
		
		
		/****************************音乐播放*************************************/
		private function playSong(e:MouseEvent):void 
		{
			if (playStatus != "play")
			{
				playStatus = "play";
				//播放pausePosition记录的停止位置
				myChannel = mySound.play(pausePosition);
				
				myChannel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			}
		}
		private function onSoundLoaded(e:Event):void 
		{
			playStatus = "play";
			//播放音乐
			myChannel=mySound.play();
			mySound.removeEventListener(Event.COMPLETE, onSoundLoaded);
			//侦听myChannel对象的SoundComplete事件，并触发onSoundCompleted方法
			myChannel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
		}
		
		private function onSoundCompleted(e:Event):void 
		{
			//播放下一首
			playId++;
			//判断playId，大于或等于音乐列表数组的长度时，将其重置为0，回到第一首歌
			if (playId >= aTracks.length)
			{
				playId = 0;
			}
			//调用loadSound方法加载音乐
			loadSound();
		}
		
		
		
		
		/**************************** 加载音乐 ************************************/
		private function loadSound():void 
		{
			var req:URLRequest = new URLRequest(aTracks[playId]);
			//新建Sound对象
			mySound = new Sound();
			//加载音乐文件
			mySound.load(req);
			//
			mySound.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
			//
			mySound.addEventListener(Event.COMPLETE, onSoundLoaded);
			//对歌曲ID进行侦听
			mySound.addEventListener(Event.ID3, onID3Load);
		}
		
		private function onID3Load(e:Event):void 
		{
			//音乐歌名等信息
			tTitle.text = mySound.id3.songName + "by" + mySound.id3.artist;
		}
		
		
		//得到下载的进度，并刷新mLoadingProgress的scaleX数值
		private function onLoadProgress(e:ProgressEvent):void 
		{
			var loadedPct:Number = (e.bytesLoaded / e.bytesTotal);
			mProgress.mLoadingProgress.scaleX = loadedPct;
		}
		
		
	}

}